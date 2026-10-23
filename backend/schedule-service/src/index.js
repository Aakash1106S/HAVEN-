require('dotenv').config();
const express = require('express');
const admin = require('firebase-admin');
const { DateTime } = require('luxon');
const cronParser = require('cron-parser');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');

// ─── Logger ──────────────────────────────────────────────────────────────────
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json(),
  ),
  transports: [new winston.transports.Console()],
});

// ─── Firebase Admin ───────────────────────────────────────────────────────────
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID || 'YOUR-PROJECT-ID',
  });
}
const db = admin.firestore();

// ─── Express Setup ────────────────────────────────────────────────────────────
const app = express();
app.use(express.json());

// ─── Schedule Execution Logic ─────────────────────────────────────────────────

/**
 * Get all enabled schedules that are due to run within the next minute.
 * This is called by Cloud Scheduler every minute.
 */
async function getDueSchedules() {
  const now = DateTime.utc();
  const windowEnd = now.plus({ minutes: 1 });

  // Query all enabled schedules whose nextRunAt is within the window
  const snapshot = await db
    .collectionGroup('schedules')
    .where('isEnabled', '==', true)
    .where('nextRunAt', '>=', admin.firestore.Timestamp.fromDate(now.toJSDate()))
    .where('nextRunAt', '<', admin.firestore.Timestamp.fromDate(windowEnd.toJSDate()))
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    homeId: doc.ref.parent.parent.id,
    ...doc.data(),
    ref: doc.ref,
  }));
}

/**
 * Calculate the next run time for a schedule based on its cron expression and timezone.
 */
function calculateNextRun(cronExpression, timezone, afterDate = new Date()) {
  try {
    const interval = cronParser.parseExpression(cronExpression, {
      currentDate: afterDate,
      tz: timezone,
    });
    return interval.next().toDate();
  } catch (err) {
    logger.error('Failed to calculate next run', { cronExpression, timezone, error: err.message });
    return null;
  }
}

/**
 * Check if a schedule should still run (within date range).
 */
function isScheduleInDateRange(schedule, now) {
  const nowDt = DateTime.fromJSDate(now).setZone(schedule.timezone);

  if (schedule.startDate) {
    const startDt = DateTime.fromJSDate(schedule.startDate.toDate()).setZone(schedule.timezone);
    if (nowDt < startDt.startOf('day')) return false;
  }

  if (schedule.endDate) {
    const endDt = DateTime.fromJSDate(schedule.endDate.toDate()).setZone(schedule.timezone);
    if (nowDt > endDt.endOf('day')) return false;
  }

  return true;
}

/**
 * Execute a single schedule: create a command in Firestore and dispatch it.
 * The command service's MQTT bridge will pick it up via Firestore trigger.
 */
async function executeSchedule(schedule) {
  const now = new Date();
  const commandId = uuidv4();
  const correlationId = uuidv4();
  const expiresAt = new Date(now.getTime() + 60 * 1000); // 60 second expiry for schedule commands

  logger.info('Executing schedule', {
    scheduleId: schedule.id,
    homeId: schedule.homeId,
    channelId: schedule.channelId,
    action: schedule.action,
  });

  try {
    const batch = db.batch();

    // Create command document
    const commandRef = db
      .collection('homes')
      .doc(schedule.homeId)
      .collection('commands')
      .doc(commandId);

    batch.set(commandRef, {
      id: commandId,
      homeId: schedule.homeId,
      channelId: schedule.channelId,
      deviceId: schedule.deviceId,
      userId: 'SYSTEM_SCHEDULE',
      action: schedule.action,
      status: 'queued',
      createdAt: admin.firestore.Timestamp.fromDate(now),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      correlationId,
      idempotencyKey: `schedule-${schedule.id}-${now.toISOString().slice(0, 16)}`, // minute-level idempotency
      sourceType: 'schedule',
      scheduleId: schedule.id,
      schemaVersion: 1,
    });

    // Update channel desired state
    const channelRef = db
      .collection('homes')
      .doc(schedule.homeId)
      .collection('channels')
      .doc(schedule.channelId);

    batch.update(channelRef, {
      desiredState: schedule.action,
      commandStatus: 'queued',
      lastCommandId: commandId,
      lastCommandAt: admin.firestore.Timestamp.fromDate(now),
    });

    // Calculate next run time
    const nextRunAt = calculateNextRun(schedule.cronExpression, schedule.timezone, now);

    // Update schedule: lastRunAt, nextRunAt, lastStatus
    const scheduleUpdate = {
      lastRunAt: admin.firestore.Timestamp.fromDate(now),
      lastStatus: 'executing',
      updatedAt: admin.firestore.Timestamp.fromDate(now),
    };

    if (nextRunAt) {
      scheduleUpdate.nextRunAt = admin.firestore.Timestamp.fromDate(nextRunAt);
    } else {
      // One-time schedule or end of recurrence — disable it
      scheduleUpdate.isEnabled = false;
      scheduleUpdate.nextRunAt = null;
    }

    batch.update(schedule.ref, scheduleUpdate);

    // Create execution record
    const execRef = schedule.ref.collection('executions').doc();
    batch.set(execRef, {
      id: execRef.id,
      scheduleId: schedule.id,
      homeId: schedule.homeId,
      scheduledAt: admin.firestore.Timestamp.fromDate(
        schedule.nextRunAt?.toDate() || now
      ),
      executedAt: admin.firestore.Timestamp.fromDate(now),
      status: 'executing',
      commandId,
      error: null,
    });

    await batch.commit();

    // Add activity event
    await db
      .collection('homes')
      .doc(schedule.homeId)
      .collection('activity')
      .add({
        type: 'scheduleExecuted',
        title: 'Schedule triggered',
        message: `Turning ${schedule.action.toUpperCase()} "${schedule.applianceName || schedule.channelId}"`,
        metadata: {
          scheduleId: schedule.id,
          channelId: schedule.channelId,
          commandId,
          action: schedule.action,
        },
        createdAt: admin.firestore.Timestamp.fromDate(now),
        read: false,
      });

    logger.info('Schedule executed successfully', { scheduleId: schedule.id, commandId });

    // Update execution record to 'dispatched' (command was created)
    await execRef.update({ status: 'dispatched' });

    return { success: true, commandId };
  } catch (err) {
    logger.error('Failed to execute schedule', {
      scheduleId: schedule.id,
      error: err.message,
      stack: err.stack,
    });

    // Record failure in schedule
    await schedule.ref.update({
      lastStatus: 'failed',
      updatedAt: admin.firestore.Timestamp.fromDate(now),
    });

    // Add failure activity
    await db
      .collection('homes')
      .doc(schedule.homeId)
      .collection('activity')
      .add({
        type: 'scheduleFailed',
        title: 'Schedule failed',
        message: `Failed to execute schedule for "${schedule.applianceName || schedule.channelId}": ${err.message}`,
        metadata: { scheduleId: schedule.id, channelId: schedule.channelId },
        createdAt: admin.firestore.Timestamp.fromDate(now),
        read: false,
      });

    return { success: false, error: err.message };
  }
}

// ─── Routes ───────────────────────────────────────────────────────────────────

/**
 * POST /execute
 * Triggered by Cloud Scheduler every minute.
 * Header: X-CloudScheduler-JobName must be set.
 */
app.post('/execute', async (req, res) => {
  // Verify this request is from Cloud Scheduler
  const jobName = req.headers['x-cloudscheduler-jobname'];
  if (!jobName && process.env.NODE_ENV !== 'development') {
    logger.warn('Received /execute request without Cloud Scheduler header');
    return res.status(403).json({ error: 'Forbidden: Not a Cloud Scheduler request' });
  }

  const executionStartTime = Date.now();
  logger.info('Schedule execution triggered', { jobName });

  try {
    const dueSchedules = await getDueSchedules();
    logger.info(`Found ${dueSchedules.length} due schedules`);

    if (dueSchedules.length === 0) {
      return res.json({ executed: 0, message: 'No schedules due' });
    }

    const results = [];
    for (const schedule of dueSchedules) {
      const now = new Date();

      // Check date range
      if (!isScheduleInDateRange(schedule, now)) {
        logger.info('Schedule out of date range, skipping', { scheduleId: schedule.id });
        results.push({ scheduleId: schedule.id, skipped: true, reason: 'out_of_date_range' });
        continue;
      }

      const result = await executeSchedule(schedule);
      results.push({ scheduleId: schedule.id, ...result });
    }

    const elapsed = Date.now() - executionStartTime;
    logger.info('Schedule execution complete', {
      total: dueSchedules.length,
      executed: results.filter((r) => r.success).length,
      failed: results.filter((r) => !r.success && !r.skipped).length,
      skipped: results.filter((r) => r.skipped).length,
      elapsedMs: elapsed,
    });

    return res.json({
      executed: results.filter((r) => r.success).length,
      failed: results.filter((r) => !r.success && !r.skipped).length,
      skipped: results.filter((r) => r.skipped).length,
      results,
    });
  } catch (err) {
    logger.error('Schedule execution failed', { error: err.message, stack: err.stack });
    return res.status(500).json({ error: 'Internal server error', message: err.message });
  }
});

/**
 * POST /schedules/initialize-next-run
 * Called when a schedule is created or updated to compute the initial nextRunAt.
 * This can also be triggered by a Firestore Cloud Function.
 */
app.post('/schedules/initialize-next-run', async (req, res) => {
  const { homeId, scheduleId } = req.body;

  if (!homeId || !scheduleId) {
    return res.status(400).json({ error: 'Missing homeId or scheduleId' });
  }

  try {
    const scheduleRef = db
      .collection('homes')
      .doc(homeId)
      .collection('schedules')
      .doc(scheduleId);

    const scheduleDoc = await scheduleRef.get();
    if (!scheduleDoc.exists) {
      return res.status(404).json({ error: 'Schedule not found' });
    }

    const schedule = scheduleDoc.data();
    const nextRunAt = calculateNextRun(schedule.cronExpression, schedule.timezone);

    if (nextRunAt) {
      await scheduleRef.update({
        nextRunAt: admin.firestore.Timestamp.fromDate(nextRunAt),
        updatedAt: admin.firestore.Timestamp.fromDate(new Date()),
      });
      return res.json({ nextRunAt: nextRunAt.toISOString() });
    } else {
      return res.status(400).json({ error: 'Could not calculate next run time' });
    }
  } catch (err) {
    logger.error('Failed to initialize next run', { error: err.message });
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /health
 */
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'haven-schedule-service', timestamp: new Date().toISOString() });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
const PORT = parseInt(process.env.PORT || '8081');
const server = app.listen(PORT, () => {
  logger.info(`Haven Schedule Service running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

module.exports = app; // For testing

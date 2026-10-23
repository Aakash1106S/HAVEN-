const express = require('express');
const { z } = require('zod');
const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');
const { db } = require('../firebase');
const config = require('../config');
const logger = require('../utils/logger');
const mqttClient = require('../mqtt/client');
const { verifyHomeAccess } = require('../utils/authorization');
const { verifyFirebaseToken } = require('../middleware/auth');
const { commandLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

const commandSchema = z.object({
  homeId: z.string().min(1, 'homeId is required'),
  channelId: z.string().min(1, 'channelId is required'),
  action: z.enum(['on', 'off'], {
    errorMap: () => ({ message: 'action must be either "on" or "off"' }),
  }),
  idempotencyKey: z.string().uuid('idempotencyKey must be a valid UUID'),
});

router.post('/', commandLimiter, verifyFirebaseToken, async (req, res) => {
  // 1. Validate request body with Zod
  const parseResult = commandSchema.safeParse(req.body);
  if (!parseResult.success) {
    const issues = parseResult.error.issues.map((i) => ({
      field: i.path.join('.'),
      message: i.message,
    }));
    return res.status(400).json({
      error: 'Validation Error',
      message: 'Invalid request body',
      details: issues,
    });
  }

  const { homeId, channelId, action, idempotencyKey } = parseResult.data;
  const userId = req.user.uid;

  try {
    // 2. Verify user owns or has access to the home
    try {
      await verifyHomeAccess(db, userId, homeId);
    } catch (authErr) {
      const statusCode = authErr.statusCode || 403;
      return res.status(statusCode).json({
        error: statusCode === 404 ? 'Not Found' : 'Forbidden',
        message: authErr.message,
      });
    }

    // 3. Get channel and device from Firestore
    let channelDoc = await db.collection('channels').doc(channelId).get();
    if (!channelDoc.exists) {
      channelDoc = await db.collection('homes').doc(homeId).collection('channels').doc(channelId).get();
    }
    if (!channelDoc.exists) {
      // Check collectionGroup as fallback
      const groupSnap = await db.collectionGroup('channels').where('id', '==', channelId).limit(1).get();
      if (!groupSnap.empty) {
        channelDoc = groupSnap.docs[0];
      }
    }

    if (!channelDoc.exists) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Channel ${channelId} not found`,
      });
    }

    const channel = channelDoc.data();
    const deviceId = channel.deviceId;
    if (!deviceId) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Device reference missing for channel ${channelId}`,
      });
    }

    let deviceDoc = await db.collection('devices').doc(deviceId).get();
    if (!deviceDoc.exists) {
      deviceDoc = await db.collection('homes').doc(homeId).collection('devices').doc(deviceId).get();
    }

    if (!deviceDoc.exists) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Device ${deviceId} not found`,
      });
    }

    const device = deviceDoc.data();

    // 4. Check device is not a foreign device
    if (device.homeId !== homeId || device.isForeign === true) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Device does not belong to this home',
      });
    }

    // 5. Check for duplicate idempotencyKey (return existing command if duplicate)
    const existingCmdSnap = await db.collection('commands')
      .where('idempotencyKey', '==', idempotencyKey)
      .limit(1)
      .get();

    if (!existingCmdSnap.empty) {
      const existingDoc = existingCmdSnap.docs[0];
      const existing = existingDoc.data();
      logger.info('Duplicate idempotency key detected, returning existing command', {
        idempotencyKey,
        commandId: existing.id || existingDoc.id,
      });
      return res.status(200).json({
        commandId: existing.id || existingDoc.id,
        status: existing.status,
        message: 'Command already processed',
      });
    }

    // 6. Create command document in Firestore with status 'queued'
    const commandId = uuidv4();
    const now = admin.firestore.Timestamp.now();
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + config.commandTimeout * 1000)
    );

    const commandData = {
      id: commandId,
      homeId,
      deviceId,
      channelId,
      channelIndex: channel.channelIndex ?? 0,
      action,
      idempotencyKey,
      status: 'queued',
      userId,
      createdAt: now,
      expiresAt,
    };

    await db.collection('commands').doc(commandId).set(commandData);

    // 7. Update channel desiredState and commandStatus in Firestore
    const channelUpdate = {
      desiredState: action,
      commandStatus: 'queued',
      updatedAt: now,
    };
    await channelDoc.ref.update(channelUpdate).catch((err) => {
      logger.warn('Failed to update channel desired state', { channelId, error: err.message });
    });

    // 8. Publish MQTT command message
    const commandPayload = {
      commandId,
      channelId,
      channelIndex: channel.channelIndex ?? 0,
      action,
      timestamp: Date.now(),
    };

    try {
      await mqttClient.publishCommand(homeId, deviceId, commandPayload);
    } catch (mqttError) {
      logger.error('Failed to publish command via MQTT', {
        commandId,
        deviceId,
        error: mqttError.message,
      });

      const failedAt = admin.firestore.Timestamp.now();
      await db.collection('commands').doc(commandId).update({
        status: 'failed',
        error: mqttError.message,
        failedAt,
      });
      await channelDoc.ref.update({
        commandStatus: 'failed',
        updatedAt: failedAt,
      }).catch(() => {});

      return res.status(502).json({
        error: 'Bad Gateway',
        message: 'Failed to dispatch command to device broker',
        commandId,
        status: 'failed',
      });
    }

    // 9. Update command status to 'dispatched'
    const dispatchedAt = admin.firestore.Timestamp.now();
    await db.collection('commands').doc(commandId).update({
      status: 'dispatched',
      dispatchedAt,
    });
    await channelDoc.ref.update({
      commandStatus: 'dispatched',
      updatedAt: dispatchedAt,
    }).catch(() => {});

    logger.info('Command successfully dispatched', { commandId, deviceId, action });

    // 10. Return { commandId, status: 'dispatched' }
    return res.status(201).json({
      commandId,
      status: 'dispatched',
    });
  } catch (error) {
    logger.error('Unexpected error processing command', { error: error.message, stack: error.stack });
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to process command',
    });
  }
});

module.exports = router;

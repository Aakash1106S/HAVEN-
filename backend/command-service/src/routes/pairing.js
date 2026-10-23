const express = require('express');
const crypto = require('crypto');
const { z } = require('zod');
const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');
const { db } = require('../firebase');
const logger = require('../utils/logger');
const { verifyHomeOwnership } = require('../utils/authorization');
const { verifyFirebaseToken } = require('../middleware/auth');
const { pairingLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

const pairSchema = z.object({
  homeId: z.string().min(1, 'homeId is required'),
  deviceName: z.string().min(1, 'deviceName is required').max(64, 'deviceName too long'),
  pairingCode: z.string().min(4, 'pairingCode is required'),
});

/**
 * Hashes an MQTT password using PBKDF2 with a cryptographic salt.
 */
function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.pbkdf2Sync(password, salt, 10000, 64, 'sha512').toString('hex');
  return `${salt}:${hash}`;
}

router.post('/pair', pairingLimiter, verifyFirebaseToken, async (req, res) => {
  // 1. Validate request body
  const parseResult = pairSchema.safeParse(req.body);
  if (!parseResult.success) {
    const issues = parseResult.error.issues.map((i) => ({
      field: i.path.join('.'),
      message: i.message,
    }));
    return res.status(400).json({
      error: 'Validation Error',
      message: 'Invalid pairing request',
      details: issues,
    });
  }

  const { homeId, deviceName, pairingCode } = parseResult.data;
  const userId = req.user.uid;

  try {
    // 2. Verify user owns the home
    try {
      await verifyHomeOwnership(db, userId, homeId);
    } catch (authErr) {
      const statusCode = authErr.statusCode || 403;
      return res.status(statusCode).json({
        error: statusCode === 404 ? 'Not Found' : 'Forbidden',
        message: authErr.message,
      });
    }

    // 3. Validate pairing code against active pairing sessions
    let sessionSnap = await db.collection('homes')
      .doc(homeId)
      .collection('pairingSessions')
      .where('pairingCode', '==', pairingCode.toUpperCase().trim())
      .where('status', '==', 'active')
      .limit(1)
      .get();

    if (sessionSnap.empty) {
      // Check top-level pairingSessions
      sessionSnap = await db.collection('pairingSessions')
        .where('homeId', '==', homeId)
        .where('pairingCode', '==', pairingCode.toUpperCase().trim())
        .where('status', '==', 'active')
        .limit(1)
        .get();
    }

    if (sessionSnap.empty) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid or inactive pairing code',
      });
    }

    const sessionDoc = sessionSnap.docs[0];
    const sessionData = sessionDoc.data();
    const expiresAt = sessionData.expiresAt?.toDate
      ? sessionData.expiresAt.toDate()
      : new Date(sessionData.expiresAt);

    if (expiresAt < new Date()) {
      await sessionDoc.ref.update({ status: 'expired' }).catch(() => {});
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Pairing code has expired',
      });
    }

    // 4. Generate device ID and unique MQTT credentials
    const deviceId = uuidv4();
    const mqttUsername = `device-${deviceId}`;
    const mqttPassword = crypto.randomBytes(24).toString('base64url').slice(0, 32);
    const hashedPassword = hashPassword(mqttPassword);

    const now = admin.firestore.Timestamp.now();
    const batch = db.batch();

    // 4. Create device document in Firestore (both top-level and in home subcollection)
    const deviceData = {
      id: deviceId,
      homeId,
      name: deviceName,
      online: false,
      isForeign: false,
      mqttUsername,
      mqttPasswordHash: hashedPassword,
      channelCount: 3,
      status: 'paired',
      pairedAt: now,
      createdAt: now,
      updatedAt: now,
    };

    const topDeviceRef = db.collection('devices').doc(deviceId);
    const homeDeviceRef = db.collection('homes').doc(homeId).collection('devices').doc(deviceId);

    batch.set(topDeviceRef, deviceData);
    batch.set(homeDeviceRef, deviceData);

    // 5. Create 3 channel documents (channels 0, 1, 2) for the device
    for (let i = 0; i < 3; i++) {
      const channelId = `${deviceId}-ch${i}`;
      const channelData = {
        id: channelId,
        deviceId,
        homeId,
        channelIndex: i,
        name: `Switch ${i + 1}`,
        desiredState: 'off',
        reportedState: 'off',
        commandStatus: 'idle',
        createdAt: now,
        updatedAt: now,
      };

      const topChannelRef = db.collection('channels').doc(channelId);
      const homeChannelRef = homeDeviceRef.collection('channels').doc(channelId);

      batch.set(topChannelRef, channelData);
      batch.set(homeChannelRef, channelData);
    }

    // 9. Mark pairing session as completed
    batch.update(sessionDoc.ref, {
      status: 'completed',
      deviceId,
      completedAt: now,
      updatedAt: now,
    });

    await batch.commit();

    logger.info('Device successfully paired', { deviceId, homeId, deviceName });

    // 8. Return { deviceId, mqttUsername, mqttPassword } - only time plaintext password is returned
    return res.status(201).json({
      deviceId,
      mqttUsername,
      mqttPassword,
    });
  } catch (error) {
    logger.error('Error during device pairing', { error: error.message, stack: error.stack });
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to pair device',
    });
  }
});

module.exports = router;

const express = require('express');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');
const { db } = require('../firebase');
const logger = require('../utils/logger');
const { verifyHomeAccess, verifyHomeOwnership } = require('../utils/authorization');
const { verifyFirebaseToken } = require('../middleware/auth');
const { generalLimiter, pairingLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

/**
 * Generate a random 6-character alphanumeric pairing code (A-Z, 2-9).
 */
function generatePairingCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = crypto.randomBytes(6);
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
}

/**
 * GET /api/homes/:homeId/devices/:deviceId/status
 * Fetches device status and all associated channel states.
 */
router.get('/:homeId/devices/:deviceId/status', generalLimiter, verifyFirebaseToken, async (req, res) => {
  const { homeId, deviceId } = req.params;
  const userId = req.user.uid;

  try {
    // 1. Verify token and home access
    try {
      await verifyHomeAccess(db, userId, homeId);
    } catch (authErr) {
      const statusCode = authErr.statusCode || 403;
      return res.status(statusCode).json({
        error: statusCode === 404 ? 'Not Found' : 'Forbidden',
        message: authErr.message,
      });
    }

    // 2. Get device from Firestore
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
    if (device.homeId !== homeId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Device does not belong to the specified home',
      });
    }

    // 3. Get all channels for device
    let channels = [];
    const channelsSnap = await db.collection('channels')
      .where('deviceId', '==', deviceId)
      .get();

    if (!channelsSnap.empty) {
      channels = channelsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    } else {
      // Check subcollection
      const subSnap = await db.collection('homes')
        .doc(homeId)
        .collection('devices')
        .doc(deviceId)
        .collection('channels')
        .get();
      channels = subSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    }

    // Sort channels by channelIndex
    channels.sort((a, b) => (a.channelIndex ?? 0) - (b.channelIndex ?? 0));

    // 4. Return device status + channel states
    return res.status(200).json({
      device: {
        id: device.id || deviceId,
        homeId: device.homeId,
        name: device.name,
        online: Boolean(device.online),
        lastSeenAt: device.lastSeenAt || null,
        status: device.status || (device.online ? 'online' : 'offline'),
      },
      channels: channels.map((ch) => ({
        id: ch.id,
        channelIndex: ch.channelIndex,
        name: ch.name,
        desiredState: ch.desiredState || 'off',
        reportedState: ch.reportedState || 'off',
        commandStatus: ch.commandStatus || 'idle',
        lastReportedAt: ch.lastReportedAt || null,
      })),
    });
  } catch (error) {
    logger.error('Error fetching device status', { homeId, deviceId, error: error.message });
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve device status',
    });
  }
});

/**
 * POST /api/homes/:homeId/pairing-sessions
 * Creates a pairing session with a 6-character alphanumeric code expiring in 5 minutes.
 */
router.post('/:homeId/pairing-sessions', pairingLimiter, verifyFirebaseToken, async (req, res) => {
  const { homeId } = req.params;
  const userId = req.user.uid;

  try {
    // Verify user owns the home
    try {
      await verifyHomeOwnership(db, userId, homeId);
    } catch (authErr) {
      const statusCode = authErr.statusCode || 403;
      return res.status(statusCode).json({
        error: statusCode === 404 ? 'Not Found' : 'Forbidden',
        message: authErr.message,
      });
    }

    const sessionId = uuidv4();
    const pairingCode = generatePairingCode();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes
    const now = admin.firestore.Timestamp.now();
    const expiresAtTimestamp = admin.firestore.Timestamp.fromDate(expiresAt);

    const sessionData = {
      id: sessionId,
      homeId,
      pairingCode,
      status: 'active',
      createdBy: userId,
      createdAt: now,
      expiresAt: expiresAtTimestamp,
    };

    const batch = db.batch();
    batch.set(db.collection('homes').doc(homeId).collection('pairingSessions').doc(sessionId), sessionData);
    batch.set(db.collection('pairingSessions').doc(sessionId), sessionData);
    await batch.commit();

    logger.info('Created device pairing session', { homeId, sessionId, pairingCode });

    return res.status(201).json({
      sessionId,
      pairingCode,
      expiresAt: expiresAt.toISOString(),
    });
  } catch (error) {
    logger.error('Error creating pairing session', { homeId, error: error.message });
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create pairing session',
    });
  }
});

module.exports = router;

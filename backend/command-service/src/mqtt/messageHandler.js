const admin = require('firebase-admin');
const { db } = require('../firebase');
const logger = require('../utils/logger');

/**
 * Parses message payload as JSON or plain string.
 */
function parsePayload(message) {
  const rawString = Buffer.isBuffer(message) ? message.toString('utf-8') : String(message);
  try {
    return { isJson: true, data: JSON.parse(rawString), raw: rawString };
  } catch {
    return { isJson: false, data: rawString, raw: rawString };
  }
}

/**
 * Handles incoming MQTT messages from devices.
 * Topics:
 *   haven/{homeId}/{deviceId}/state
 *   haven/{homeId}/{deviceId}/state/{channelId}
 *   haven/{homeId}/{deviceId}/ack
 *   haven/{homeId}/{deviceId}/availability
 */
async function handleMessage(topic, message) {
  try {
    if (!topic || !message) {
      logger.warn('MQTT message received without topic or payload');
      return;
    }

    const topicParts = topic.split('/');
    if (topicParts.length < 4 || topicParts[0] !== 'haven') {
      logger.debug('Ignoring non-Haven topic', { topic });
      return;
    }

    const homeId = topicParts[1];
    const deviceId = topicParts[2];
    const messageType = topicParts[3];
    const subPath = topicParts[4]; // optional channelId

    const { isJson, data, raw } = parsePayload(message);

    logger.info('MQTT message received', {
      topic,
      homeId,
      deviceId,
      messageType,
      subPath,
      payload: isJson ? data : raw,
    });

    switch (messageType) {
      case 'state':
        await handleStateReport(homeId, deviceId, subPath, isJson ? data : raw);
        break;
      case 'ack':
        await handleAckMessage(homeId, deviceId, isJson ? data : raw);
        break;
      case 'availability':
        await handleAvailability(homeId, deviceId, isJson ? data : raw);
        break;
      default:
        logger.debug('Unhandled messageType on topic', { messageType, topic });
    }
  } catch (error) {
    logger.error('Error handling MQTT message', {
      topic,
      error: error.message,
      stack: error.stack,
    });
  }
}

/**
 * Handles device state reports and updates channel documents.
 */
async function handleStateReport(homeId, deviceId, subPathChannelId, payload) {
  if (!db) {
    logger.warn('Firestore db not available for state report');
    return;
  }

  const timestamp = admin.firestore.FieldValue.serverTimestamp();

  // Helper to update a channel doc
  async function updateChannel(channelId, state) {
    const normalizedState = typeof state === 'string' ? state.toLowerCase() : state ? 'on' : 'off';
    const updateData = {
      reportedState: normalizedState,
      lastReportedAt: timestamp,
      commandStatus: 'idle',
      updatedAt: timestamp,
    };

    try {
      const topLevelRef = db.collection('channels').doc(channelId);
      const homeSubRef = db.collection('homes').doc(homeId).collection('devices').doc(deviceId).collection('channels').doc(channelId);

      await Promise.allSettled([
        topLevelRef.update(updateData),
        homeSubRef.update(updateData),
      ]);

      logger.info('Updated channel state', { channelId, state: normalizedState });
    } catch (err) {
      logger.warn('Failed to update channel state', { channelId, error: err.message });
    }
  }

  // 1. If channelId is in topic: haven/{homeId}/{deviceId}/state/{channelId}
  if (subPathChannelId) {
    const state = typeof payload === 'object' && payload !== null ? (payload.state || payload.reportedState) : payload;
    if (state !== undefined) {
      await updateChannel(subPathChannelId, state);
      return;
    }
  }

  // 2. If payload is an object with channelId and state
  if (typeof payload === 'object' && payload !== null) {
    if (payload.channelId && (payload.state !== undefined || payload.reportedState !== undefined)) {
      await updateChannel(payload.channelId, payload.state || payload.reportedState);
      return;
    }

    // 3. If payload contains multiple channels: { channels: [{ id, state }] } or { "0": "on", "1": "off" }
    if (Array.isArray(payload.channels)) {
      for (const ch of payload.channels) {
        const chId = ch.channelId || ch.id || `${deviceId}-ch${ch.channelIndex ?? 0}`;
        if (ch.state !== undefined) {
          await updateChannel(chId, ch.state);
        }
      }
      return;
    }

    if (payload.channels && typeof payload.channels === 'object') {
      for (const [key, val] of Object.entries(payload.channels)) {
        const chId = isNaN(key) ? key : `${deviceId}-ch${key}`;
        const state = typeof val === 'object' ? val.state : val;
        await updateChannel(chId, state);
      }
      return;
    }

    // Single channel index in payload
    if (payload.channelIndex !== undefined && payload.state !== undefined) {
      const chId = `${deviceId}-ch${payload.channelIndex}`;
      await updateChannel(chId, payload.state);
      return;
    }
  }

  logger.warn('Unrecognized state report format', { homeId, deviceId, payload });
}

/**
 * Handles command acknowledgement messages from devices.
 * Updates command status to 'acknowledged' then 'succeeded'.
 */
async function handleAckMessage(homeId, deviceId, payload) {
  if (!db) {
    logger.warn('Firestore db not available for ack handling');
    return;
  }

  const commandId = typeof payload === 'object' ? payload.commandId : null;
  if (!commandId) {
    logger.warn('Ack message received without commandId', { payload });
    return;
  }

  try {
    const commandRef = db.collection('commands').doc(commandId);
    const commandDoc = await commandRef.get();

    if (!commandDoc.exists) {
      logger.warn('Ack received for non-existent command', { commandId });
      return;
    }

    const timestamp = admin.firestore.Timestamp.now();
    const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

    // 1. Update command status to 'acknowledged'
    await commandRef.update({
      status: 'acknowledged',
      acknowledgedAt: serverTimestamp,
    });
    logger.info('Command acknowledged', { commandId });

    // 2. Update command status to 'succeeded'
    await commandRef.update({
      status: 'succeeded',
      completedAt: serverTimestamp,
    });
    logger.info('Command succeeded', { commandId });

    // 3. Update channel commandStatus and reportedState
    const commandData = commandDoc.data();
    const channelId = commandData.channelId || payload.channelId;
    const action = commandData.action || payload.action;

    if (channelId) {
      const channelUpdate = {
        commandStatus: 'succeeded',
        updatedAt: serverTimestamp,
      };
      if (action) {
        channelUpdate.reportedState = action;
        channelUpdate.lastReportedAt = serverTimestamp;
      }

      await Promise.allSettled([
        db.collection('channels').doc(channelId).update(channelUpdate),
        db.collection('homes').doc(homeId).collection('devices').doc(deviceId).collection('channels').doc(channelId).update(channelUpdate),
      ]);
    }
  } catch (error) {
    logger.error('Failed to process command ack', { commandId, error: error.message });
  }
}

/**
 * Handles device availability (online/offline).
 */
async function handleAvailability(homeId, deviceId, payload) {
  if (!db) {
    logger.warn('Firestore db not available for availability update');
    return;
  }

  let isOnline = false;
  if (typeof payload === 'object' && payload !== null) {
    isOnline = payload.status === 'online' || payload.online === true || payload.state === 'online';
  } else if (typeof payload === 'string') {
    isOnline = payload.trim().toLowerCase() === 'online';
  }

  const timestamp = admin.firestore.FieldValue.serverTimestamp();
  const updateData = {
    online: isOnline,
    lastSeenAt: timestamp,
    updatedAt: timestamp,
  };

  try {
    await Promise.allSettled([
      db.collection('devices').doc(deviceId).update(updateData),
      db.collection('homes').doc(homeId).collection('devices').doc(deviceId).update(updateData),
    ]);

    logger.info('Updated device availability', { deviceId, isOnline });
  } catch (err) {
    logger.warn('Failed to update device availability in Firestore', { deviceId, error: err.message });
  }
}

module.exports = {
  handleMessage,
  handleStateReport,
  handleAckMessage,
  handleAvailability,
  parsePayload,
};

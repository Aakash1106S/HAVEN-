const admin = require('firebase-admin');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const config = require('./config');
const logger = require('./utils/logger');

if (admin.getApps().length === 0) {
  try {
    const options = {};
    if (config.firebase.projectId) {
      options.projectId = config.firebase.projectId;
    }
    admin.initializeApp(options);
    logger.info('Firebase Admin SDK initialized', { projectId: config.firebase.projectId });
  } catch (error) {
    logger.error('Failed to initialize Firebase Admin SDK', { error: error.message });
  }
}

let db = null;
try {
  db = getFirestore();
} catch (error) {
  logger.warn('Firestore initialization warning (may be mocked in test)', { error: error.message });
}

// Attach compatibility helpers so legacy calls work seamlessly
admin.firestore = getFirestore;
admin.firestore.FieldValue = FieldValue;
admin.firestore.Timestamp = Timestamp;
admin.auth = getAuth;

module.exports = { admin, db, getFirestore, getAuth, FieldValue, Timestamp };

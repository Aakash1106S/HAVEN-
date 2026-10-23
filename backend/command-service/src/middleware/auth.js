const { admin } = require('../firebase');
const logger = require('../utils/logger');

async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized', message: 'Missing Bearer token' });
  }

  try {
    const idToken = authHeader.split('Bearer ')[1].trim();
    if (!idToken) {
      return res.status(401).json({ error: 'Unauthorized', message: 'Missing Bearer token' });
    }
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (err) {
    logger.warn('Token verification failed', { error: err.message });
    return res.status(401).json({ error: 'Unauthorized', message: 'Invalid token' });
  }
}

module.exports = {
  verifyFirebaseToken,
};

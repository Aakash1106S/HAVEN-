/**
 * Check if userId has access to homeId (as owner or member).
 * Throws Error('Home not found') if home does not exist.
 * Throws Error('Unauthorized: not a home member') if user lacks access.
 * Returns the home data object with id.
 */
async function verifyHomeAccess(db, userId, homeId) {
  if (!homeId) {
    const error = new Error('Home ID is required');
    error.statusCode = 400;
    throw error;
  }

  const homeDoc = await db.collection('homes').doc(homeId).get();
  if (!homeDoc.exists) {
    const error = new Error('Home not found');
    error.statusCode = 404;
    throw error;
  }

  const home = homeDoc.data();
  const isOwner = home.ownerId === userId;
  const isMember = Array.isArray(home.memberIds) && home.memberIds.includes(userId);

  if (!isOwner && !isMember) {
    const error = new Error('Unauthorized: not a home member');
    error.statusCode = 403;
    throw error;
  }

  return { id: homeDoc.id, ...home };
}

/**
 * Check if userId is the owner of homeId.
 * Throws Error('Home not found') if home does not exist.
 * Throws Error('Forbidden: user is not the home owner') if user is not the owner.
 * Returns the home data object with id.
 */
async function verifyHomeOwnership(db, userId, homeId) {
  if (!homeId) {
    const error = new Error('Home ID is required');
    error.statusCode = 400;
    throw error;
  }

  const homeDoc = await db.collection('homes').doc(homeId).get();
  if (!homeDoc.exists) {
    const error = new Error('Home not found');
    error.statusCode = 404;
    throw error;
  }

  const home = homeDoc.data();
  if (home.ownerId !== userId) {
    const error = new Error('Forbidden: user is not the home owner');
    error.statusCode = 403;
    throw error;
  }

  return { id: homeDoc.id, ...home };
}

module.exports = {
  verifyHomeAccess,
  verifyHomeOwnership,
};

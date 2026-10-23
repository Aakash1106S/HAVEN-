const { verifyHomeAccess, verifyHomeOwnership } = require('../src/utils/authorization');

describe('Authorization Utilities', () => {
  const mockDb = (homeData) => ({
    collection: jest.fn().mockReturnValue({
      doc: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: homeData !== null,
          id: 'home-123',
          data: () => homeData,
        }),
      }),
    }),
  });

  describe('verifyHomeAccess', () => {
    it('grants access to home owner', async () => {
      const db = mockDb({ ownerId: 'user-owner', memberIds: [] });
      const result = await verifyHomeAccess(db, 'user-owner', 'home-123');
      expect(result.id).toBe('home-123');
      expect(result.ownerId).toBe('user-owner');
    });

    it('grants access to home member', async () => {
      const db = mockDb({ ownerId: 'user-owner', memberIds: ['user-member'] });
      const result = await verifyHomeAccess(db, 'user-member', 'home-123');
      expect(result.id).toBe('home-123');
    });

    it('throws 403 error for non-member', async () => {
      const db = mockDb({ ownerId: 'user-owner', memberIds: ['user-member'] });
      await expect(verifyHomeAccess(db, 'stranger', 'home-123')).rejects.toThrow(
        'Unauthorized: not a home member'
      );
    });

    it('throws 404 error if home does not exist', async () => {
      const db = mockDb(null);
      await expect(verifyHomeAccess(db, 'user-owner', 'nonexistent')).rejects.toThrow(
        'Home not found'
      );
    });
  });

  describe('verifyHomeOwnership', () => {
    it('grants access to owner', async () => {
      const db = mockDb({ ownerId: 'user-owner' });
      const result = await verifyHomeOwnership(db, 'user-owner', 'home-123');
      expect(result.ownerId).toBe('user-owner');
    });

    it('denies access to non-owner member', async () => {
      const db = mockDb({ ownerId: 'user-owner', memberIds: ['user-member'] });
      await expect(verifyHomeOwnership(db, 'user-member', 'home-123')).rejects.toThrow(
        'Forbidden: user is not the home owner'
      );
    });
  });
});

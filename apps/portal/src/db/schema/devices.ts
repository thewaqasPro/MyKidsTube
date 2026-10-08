import { sqliteTable, text, integer, index } from 'drizzle-orm/sqlite-core';
import { families, childProfiles } from './profiles';

export const devices = sqliteTable('devices', {
  id: text('id').primaryKey(),
  familyId: text('family_id').references(() => families.id),
  profileId: text('profile_id').references(() => childProfiles.id),
  deviceName: text('device_name').notNull(),
  pairingCode: text('pairing_code').unique(),
  status: text('status').default('pending'),
  authToken: text('auth_token'),
  createdAt: text('created_at').notNull(),
  expiresAt: text('expires_at'),
  used: integer('used').default(0),
  rawTokenPending: text('raw_token_pending'),
});

export const adminSettings = sqliteTable('admin_settings', {
  key: text('key').primaryKey(),
  value: text('value'),
});

export const parentSessions = sqliteTable(
  'parent_sessions',
  {
    tokenHash: text('token_hash').primaryKey(),
    createdAt: text('created_at').notNull(),
    expiresAt: text('expires_at').notNull(),
  },
  (table) => [
    index('idx_parent_sessions_expires_at').on(table.expiresAt),
  ]
);

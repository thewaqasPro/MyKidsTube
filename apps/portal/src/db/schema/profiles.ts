import { sqliteTable, text, integer, primaryKey } from 'drizzle-orm/sqlite-core';
import { videos } from './catalog';

export const families = sqliteTable('families', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  parentPin: text('parent_pin').default('1234'),
  createdAt: text('created_at').notNull(),
});

export const childProfiles = sqliteTable('child_profiles', {
  id: text('id').primaryKey(),
  familyId: text('family_id')
    .notNull()
    .references(() => families.id),
  name: text('name').notNull(),
  avatarIcon: text('avatar_icon').default('bear'),
  ageBracket: text('age_bracket').default('all'),
  createdAt: text('created_at').notNull(),
});

export const profileVideoAssignments = sqliteTable(
  'profile_video_assignments',
  {
    profileId: text('profile_id')
      .notNull()
      .references(() => childProfiles.id),
    videoId: text('video_id')
      .notNull()
      .references(() => videos.id),
    categoryId: text('category_id').notNull(),
    createdAt: text('created_at').notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.profileId, table.videoId] }),
  ]
);

export const deviceProfileLinks = sqliteTable(
  'device_profile_links',
  {
    deviceId: text('device_id').notNull(),
    profileId: text('profile_id')
      .notNull()
      .references(() => childProfiles.id, { onDelete: 'cascade' }),
    isActive: integer('is_active').default(0),
    lastSwitchedAt: text('last_switched_at').notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.deviceId, table.profileId] }),
  ]
);

import { sqliteTable, text, integer, real, index } from 'drizzle-orm/sqlite-core';

export const watchEvents = sqliteTable(
  'watch_events',
  {
    id: text('id').primaryKey(),
    videoId: text('video_id').notNull(),
    deviceId: text('device_id').default('kids_tablet'),
    profileId: text('profile_id').default('kids_all'),
    secondsWatched: integer('seconds_watched').notNull().default(0),
    videoDuration: integer('video_duration').default(0),
    completionRate: real('completion_rate').default(0.0),
    isCompleted: integer('is_completed').default(0),
    isSkipped: integer('is_skipped').default(0),
    eventAt: text('event_at').notNull(),
  },
  (table) => [
    index('idx_watch_events_video_id').on(table.videoId),
    index('idx_watch_events_device').on(table.deviceId, table.eventAt),
    index('idx_watch_events_profile').on(table.profileId, table.eventAt),
  ]
);

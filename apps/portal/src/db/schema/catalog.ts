import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const categories = sqliteTable('categories', {
  id: text('id').primaryKey(),
  name: text('name').notNull().unique(),
  icon: text('icon').default('category'),
  displayOrder: integer('display_order').default(0),
});

export const videos = sqliteTable('videos', {
  id: text('id').primaryKey(),
  title: text('title').notNull(),
  duration: integer('duration').default(0),
  durationFormatted: text('duration_formatted').default('00:00'),
  categoryId: text('category_id')
    .notNull()
    .references(() => categories.id),
  sourceUrl: text('source_url'),
  videoFile: text('video_file').notNull(),
  thumbnailFile: text('thumbnail_file').notNull(),
  fileSizeBytes: integer('file_size_bytes').default(0),
  quality: text('quality').default('720p'),
  createdAt: text('created_at').notNull(),
  channelName: text('channel_name').default(''),
  channelIcon: text('channel_icon').default(''),
  status: text('status').default('pending_download'),
  views: integer('views').default(0),
  watchSeconds: integer('watch_seconds').default(0),
  fileVerified: integer('file_verified').default(0),
  youtubeId: text('youtube_id'),
});

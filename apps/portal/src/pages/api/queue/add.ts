import type { APIRoute } from 'astro';
import { getDatabase, extractYoutubeId, fetchYoutubeOembed } from '../../../lib/db';

export const POST: APIRoute = async (context) => {
  try {
    const body = await context.request.json();
    const urls: string[] = Array.isArray(body.urls) 
      ? body.urls 
      : (body.url ? [body.url] : []);
    const categoryId = body.category_id || 'cartoons';
    const profileIds: string[] = body.allowed_profile_ids || ['kids_all'];

    if (urls.length === 0) {
      return new Response(JSON.stringify({ error: 'No URLs provided' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const db = await getDatabase(context);
    const addedVideos = [];
    const now = new Date().toISOString();

    for (const rawUrl of urls) {
      const trimmed = String(rawUrl).trim();
      if (!trimmed) continue;

      const ytId = extractYoutubeId(trimmed);
      if (!ytId) continue;

      const meta = await fetchYoutubeOembed(ytId);
      const isShort = trimmed.includes('/shorts/');
      const videoId = isShort ? `short_${ytId}` : ytId;
      const videoFile = `${ytId}.mp4`;
      const thumbFile = `${ytId}.webp`;

      if (db) {
        await db.prepare(`
          INSERT INTO videos (
            id, title, duration, duration_formatted, category_id, source_url, 
            video_file, thumbnail_file, file_size_bytes, quality, created_at, 
            channel_name, channel_icon, status, youtube_id, file_verified, views, watch_seconds
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0)
          ON CONFLICT(id) DO UPDATE SET 
            status = excluded.status,
            youtube_id = excluded.youtube_id,
            title = excluded.title
        `).bind(
          videoId,
          meta.title,
          180,
          '03:00',
          isShort ? 'shorts' : categoryId,
          trimmed,
          videoFile,
          thumbFile,
          0,
          '720p',
          now,
          meta.channel_name,
          '',
          'pending_download',
          ytId,
          0
        ).run();

        // Assign to child profiles
        for (const pId of profileIds) {
          await db.prepare(`
            INSERT OR IGNORE INTO profile_video_assignments (profile_id, video_id, category_id, created_at)
            VALUES (?, ?, ?, ?)
          `).bind(pId, videoId, isShort ? 'shorts' : categoryId, now).run();
        }
      }

      addedVideos.push({
        id: videoId,
        youtube_id: ytId,
        title: meta.title,
        channel_name: meta.channel_name,
        thumbnail_url: meta.thumbnail_url,
        status: 'pending_download',
      });
    }

    return new Response(JSON.stringify({
      success: true,
      count: addedVideos.length,
      videos: addedVideos,
      message: `${addedVideos.length} video(s) added to wishlist! Immediately playable via YouTube embed.`,
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    console.error('Queue add error:', error);
    return new Response(JSON.stringify({ error: error.message || 'Failed to add video to queue' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

import type { APIRoute } from 'astro';
import { getDatabase, extractYoutubeId, fetchYoutubeOembed } from '../../../lib/db';
import { getR2Bucket } from '../../../lib/r2';

export const POST: APIRoute = async (context) => {
  try {
    const body = await context.request.json().catch(() => ({}));
    const { url, category_id = 'cartoons', quality = '720p' } = body;

    if (!url) {
      return new Response(JSON.stringify({ error: 'URL is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const youtubeId = extractYoutubeId(url);
    if (!youtubeId) {
      return new Response(JSON.stringify({ error: 'Could not extract YouTube ID from URL' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 1. Fetch metadata via oEmbed
    const meta = await fetchYoutubeOembed(youtubeId);

    // 2. Pre-cache thumbnail to R2 if available
    const r2 = await getR2Bucket(context);
    if (r2 && meta.thumbnail_url) {
      try {
        const thumbRes = await fetch(meta.thumbnail_url);
        if (thumbRes.ok) {
          const thumbBuffer = await thumbRes.arrayBuffer();
          await r2.put(`thumbs/${youtubeId}.webp`, thumbBuffer, {
            httpMetadata: { contentType: 'image/jpeg' },
          });
        }
      } catch (r2Err) {
        console.error('Failed to pre-cache thumb to R2:', r2Err);
      }
    }

    // 3. Insert or update in D1
    const db = await getDatabase(context);
    const now = new Date().toISOString();

    if (db) {
      await db
        .prepare(`
          INSERT INTO videos (
            id, title, duration, duration_formatted, category_id, source_url,
            video_file, thumbnail_file, file_size_bytes, quality, created_at,
            channel_name, channel_icon, status, views, watch_seconds, file_verified
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            title = excluded.title,
            category_id = excluded.category_id,
            status = 'pending_download'
        `)
        .bind(
          youtubeId,
          meta.title,
          0,
          '--:--',
          category_id,
          url,
          `${youtubeId}.mp4`,
          `${youtubeId}.webp`,
          0,
          quality,
          now,
          meta.channel_name,
          meta.thumbnail_url,
          'pending_download',
          0,
          0,
          0
        )
        .run();
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Video added to catalog and queued for offline sync!',
        video: {
          id: youtubeId,
          title: meta.title,
          category_id,
          status: 'pending_download',
          stream_url: `https://kidsapi.waqas.pro/media/videos/${youtubeId}.mp4`,
          thumbnail_url: `https://mykidstube.kidstube.workers.dev/api/assets/thumbs/${youtubeId}.webp`,
          channel_name: meta.channel_name,
        },
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};

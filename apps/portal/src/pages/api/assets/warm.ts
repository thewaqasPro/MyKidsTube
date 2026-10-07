import type { APIRoute } from 'astro';
import { getDatabase } from '../../../lib/db';
import { getR2Bucket } from '../../../lib/r2';

export const POST: APIRoute = async (context) => {
  const r2 = await getR2Bucket(context);
  const db = await getDatabase(context);

  if (!r2 || !db) {
    return new Response(JSON.stringify({ error: 'R2 or DB binding missing' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const res = await db.prepare('SELECT id, thumbnail_file, youtube_id FROM videos LIMIT 30').all();
    const videos = res.results as any[];

    const results = [];
    for (const v of videos) {
      const id = v.youtube_id || v.id;
      const filename = v.thumbnail_file || `${id}.webp`;
      const r2Key = `thumbs/${filename}`;

      // Check if already in R2
      const existing = await r2.get(r2Key);
      if (existing) {
        results.push({ id, status: 'already_cached' });
        continue;
      }

      // Fetch from YouTube
      try {
        const ytRes = await fetch(`https://i.ytimg.com/vi/${id}/hqdefault.jpg`);
        if (ytRes.ok) {
          const buf = await ytRes.arrayBuffer();
          await r2.put(r2Key, buf, {
            httpMetadata: { contentType: 'image/jpeg' },
          });
          results.push({ id, status: 'cached' });
        } else {
          results.push({ id, status: 'fetch_failed' });
        }
      } catch (err: any) {
        results.push({ id, status: 'error', error: err.message });
      }
    }

    return new Response(JSON.stringify({ count: results.length, details: results }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

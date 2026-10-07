import type { APIRoute } from 'astro';
import { getDatabase } from '../../../lib/db';
import { getR2Bucket } from '../../../lib/r2';
import { requireParent } from '../../../lib/parentAuth';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['POST', 'OPTIONS']);
};

export const POST: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['POST', 'OPTIONS'], isStateChanging: true });

  const r2 = await getR2Bucket(context);
  const db = await getDatabase(context);

  if (!r2 || !db) {
    return new Response(JSON.stringify({ error: 'R2 or DB binding missing' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
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
        const ytRes = await fetch(`https://i.ytimg.com/vi/${id}/hqdefault.jpg`, {
          signal: AbortSignal.timeout(5000),
        });
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
        console.error(`Asset warm fetch error for ${id}:`, err);
        results.push({ id, status: 'error' });
      }
    }

    return new Response(JSON.stringify({ count: results.length, details: results }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (e: any) {
    console.error('assets/warm POST error:', e);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

import type { APIRoute } from 'astro';
import { recordWatchMetric, getDatabase } from '../../../lib/db';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['POST', 'OPTIONS']);
};

export const POST: APIRoute = async (context) => {
  const corsHeaders = getCorsHeaders(context.request, { methods: ['POST', 'OPTIONS'], isStateChanging: true });

  try {
    const body = await context.request.json().catch(() => ({}));
    const videoId = body.video_id;
    const deviceId = body.device_id || body.profile_id || 'kids_all';

    if (!videoId || typeof videoId !== 'string') {
      return new Response(JSON.stringify({ error: 'video_id is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const secondsRaw = Number(body.seconds_watched);
    if (isNaN(secondsRaw) || secondsRaw < 0 || secondsRaw > 86400) {
      return new Response(
        JSON.stringify({ error: 'seconds_watched must be a valid number between 0 and 86400' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    const db = await getDatabase(context);
    if (db) {
      // Validate that video exists in the database
      const videoExists = await db
        .prepare('SELECT id FROM videos WHERE id = ? OR youtube_id = ? LIMIT 1')
        .bind(videoId, videoId)
        .first();

      if (!videoExists) {
        return new Response(
          JSON.stringify({ error: 'Video not found' }),
          {
            status: 400,
            headers: { 'Content-Type': 'application/json', ...corsHeaders },
          }
        );
      }
    }

    const ok = await recordWatchMetric(videoId, deviceId, secondsRaw, context);

    return new Response(JSON.stringify({ success: ok }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error: any) {
    console.error('Watch metric recording error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

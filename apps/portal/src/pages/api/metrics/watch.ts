import type { APIRoute } from 'astro';
import { recordWatchMetric } from '../../../lib/db';

export const POST: APIRoute = async (context) => {
  try {
    const body = await context.request.json();
    const videoId = body.video_id;
    const profileId = body.profile_id || 'kids_all';
    const secondsWatched = Number(body.seconds_watched || 5);

    if (!videoId) {
      return new Response(JSON.stringify({ error: 'video_id is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const ok = await recordWatchMetric(videoId, profileId, secondsWatched, context);

    return new Response(JSON.stringify({ success: ok }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

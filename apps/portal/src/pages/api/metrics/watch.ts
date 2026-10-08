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
    // 1. Support batch sync for local-first clients
    if (Array.isArray(body.events)) {
      const db = await getDatabase(context);
      if (!db) {
        return new Response(JSON.stringify({ success: true, synced_count: 0 }), {
          status: 200,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }

      const statements: any[] = [];
      const syncedIds: string[] = [];

      for (const ev of body.events) {
        const vId = ev.video_id;
        if (!vId || typeof vId !== 'string') continue;
        const dId = ev.device_id || 'kids_tablet';
        const pId = ev.profile_id || 'kids_all';
        const secs = Math.max(0, Math.min(86400, Math.floor(Number(ev.seconds_watched) || 0)));
        if (secs <= 0) continue;

        const duration = Math.max(0, Math.floor(Number(ev.video_duration) || 0));
        const isCompleted = ev.is_completed ? 1 : (duration > 0 && secs >= 0.75 * duration ? 1 : 0);
        const isSkipped = ev.is_skipped ? 1 : (secs < 10 ? 1 : 0);
        const completionRate = duration > 0 ? Math.min(1.0, Number((secs / duration).toFixed(3))) : 0.0;

        const eventId = ev.id || ('ev_' + crypto.randomUUID());
        const eventAt = ev.watched_at
          ? (typeof ev.watched_at === 'number' ? new Date(ev.watched_at).toISOString() : String(ev.watched_at))
          : new Date().toISOString();

        statements.push(
          db.prepare(`
            INSERT OR IGNORE INTO watch_events (
              id, video_id, device_id, profile_id, seconds_watched,
              video_duration, completion_rate, is_completed, is_skipped, event_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `).bind(eventId, vId, dId, pId, secs, duration, completionRate, isCompleted, isSkipped, eventAt)
        );
        statements.push(
          db.prepare('UPDATE videos SET views = COALESCE(views, 0) + 1, watch_seconds = COALESCE(watch_seconds, 0) + ? WHERE id = ? OR youtube_id = ?')
            .bind(secs, vId, vId)
        );
        statements.push(
          db.prepare(`
            INSERT OR REPLACE INTO device_profile_links (device_id, profile_id, is_active, last_switched_at)
            VALUES (?, ?, 1, ?)
          `).bind(dId, pId, eventAt)
        );
        if (ev.id) syncedIds.push(ev.id);
      }

      // Execute in chunks of up to 80 statements for D1
      for (let i = 0; i < statements.length; i += 80) {
        await db.batch(statements.slice(i, i + 80)).catch((err: any) => {
          console.error('Batch watch sync error:', err);
        });
      }

      return new Response(JSON.stringify({ success: true, synced_count: syncedIds.length, synced_ids: syncedIds }), {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // 2. Single event flow
    const videoId = body.video_id;
    const deviceId = body.device_id || body.profile_id || 'kids_all';

    if (!videoId || typeof videoId !== 'string') {
      return new Response(JSON.stringify({ error: 'video_id or events array is required' }), {
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

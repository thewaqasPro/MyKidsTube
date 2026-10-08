import type { APIRoute } from 'astro';
import { recordWatchMetric, getDatabase } from '../../../lib/db';
import { getAuthenticatedDevice, getAuthenticatedParent } from '../../../lib/auth';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['POST', 'OPTIONS']);
};

export const POST: APIRoute = async (context) => {
  const corsHeaders = getCorsHeaders(context.request, { methods: ['POST', 'OPTIONS'], isStateChanging: true });

  // 1. Authenticate: Requires paired device token OR authenticated parent session
  const [deviceAuth, parentAuth] = await Promise.all([
    getAuthenticatedDevice(context).catch(() => null),
    getAuthenticatedParent(context).catch(() => null),
  ]);

  const isDevice = deviceAuth?.user?.role === 'device';
  const isParent = parentAuth?.user?.role === 'parent';

  if (!isDevice && !isParent) {
    return new Response(
      JSON.stringify({ error: 'unauthorized', message: 'Device authentication or parent session required' }),
      {
        status: 401,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-store',
          ...corsHeaders,
        },
      }
    );
  }

  try {
    const body = (await context.request.json().catch(() => ({}))) as Record<string, any>;

    // 2. Support batch sync for local-first clients
    if (Array.isArray(body.events)) {
      if (body.events.length === 0) {
        return new Response(JSON.stringify({ success: true, synced_count: 0, synced_ids: [] }), {
          status: 200,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }

      const db = await getDatabase(context);
      if (!db) {
        return new Response(
          JSON.stringify({ error: 'database_unavailable', message: 'Database connection is unavailable' }),
          {
            status: 503,
            headers: { 'Content-Type': 'application/json', ...corsHeaders },
          }
        );
      }

      // Check all events have non-empty string video_id
      for (const ev of body.events) {
        if (!ev || typeof ev.video_id !== 'string' || !ev.video_id.trim()) {
          return new Response(
            JSON.stringify({ error: 'bad_request', message: 'All batch events must provide a valid video_id' }),
            {
              status: 400,
              headers: { 'Content-Type': 'application/json', ...corsHeaders },
            }
          );
        }
      }

      // Validate every video_id against the videos table
      const uniqueVideoIds = Array.from(
        new Set(body.events.map((ev: any) => String(ev.video_id).trim()))
      );

      const placeholders = uniqueVideoIds.map(() => '?').join(',');
      const existingRows = await db
        .prepare(`SELECT id, youtube_id FROM videos WHERE id IN (${placeholders}) OR youtube_id IN (${placeholders})`)
        .bind(...uniqueVideoIds, ...uniqueVideoIds)
        .all();

      const validIdSet = new Set<string>();
      if (existingRows?.results) {
        for (const row of existingRows.results as any[]) {
          if (row.id) validIdSet.add(row.id);
          if (row.youtube_id) validIdSet.add(row.youtube_id);
        }
      }

      // If any video_id in the batch is bogus (not in videos table), reject the entire batch with 400
      for (const ev of body.events) {
        const vId = String(ev.video_id).trim();
        if (!validIdSet.has(vId)) {
          return new Response(
            JSON.stringify({
              error: 'bad_request',
              message: `Video ID '${vId}' not found in catalog`,
              bogus_video_id: vId,
            }),
            {
              status: 400,
              headers: { 'Content-Type': 'application/json', ...corsHeaders },
            }
          );
        }
      }

      const statements: any[] = [];
      const syncedIds: string[] = [];

      for (const ev of body.events) {
        const vId = String(ev.video_id).trim();
        const dId = ev.device_id || (isDevice ? deviceAuth?.user?.id : 'kids_tablet');
        const pId = ev.profile_id || 'kids_all';

        // Clamp watch seconds to [0, 86400] and drop 0 or negative seconds
        const secs = Math.max(0, Math.min(86400, Math.floor(Number(ev.seconds_watched) || 0)));
        if (secs <= 0) continue;

        // Clamp duration to [0, 86400]
        const duration = Math.max(0, Math.min(86400, Math.floor(Number(ev.video_duration) || 0)));
        const completionRate = duration > 0 ? Math.max(0.0, Math.min(1.0, Number((secs / duration).toFixed(3)))) : 0.0;
        const isCompleted = ev.is_completed ? 1 : (duration > 0 && secs >= 0.75 * duration ? 1 : 0);
        const isSkipped = ev.is_skipped ? 1 : (secs < 10 ? 1 : 0);

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

    // 3. Single event flow
    const videoId = typeof body.video_id === 'string' ? body.video_id.trim() : '';
    const deviceId = body.device_id || (isDevice ? deviceAuth?.user?.id : (body.profile_id || 'kids_all'));

    if (!videoId) {
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

    const ok = await recordWatchMetric(videoId, deviceId, Math.max(0, Math.min(86400, Math.floor(secondsRaw))), context);

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

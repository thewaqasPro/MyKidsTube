import type { APIRoute } from 'astro';
import { getDatabase, getDbData } from '../../../lib/db';
import { requireParent } from '../../../lib/parentAuth';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

const ALLOWED_STATUSES = new Set(['pending_download', 'ready', 'error']);

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'PATCH', 'DELETE', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'PATCH', 'DELETE', 'OPTIONS'], isStateChanging: false });

  try {
    const db = await getDatabase(context);
    if (db) {
      const res = await db.prepare('SELECT * FROM videos ORDER BY created_at DESC').all();
      return new Response(JSON.stringify(res.results || []), {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const data = await getDbData(context);
    return new Response(JSON.stringify(data.videos), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error: any) {
    console.error('studio/videos GET error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

export const DELETE: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'PATCH', 'DELETE', 'OPTIONS'], isStateChanging: true });

  try {
    const url = new URL(context.request.url);
    const id = url.searchParams.get('id');

    if (!id) {
      return new Response(JSON.stringify({ error: 'id parameter is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const db = await getDatabase(context);
    if (db) {
      // Check if video exists
      const existing = await db.prepare('SELECT id FROM videos WHERE id = ?').bind(id).first();
      if (!existing) {
        return new Response(JSON.stringify({ error: 'Video not found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }

      await db.batch([
        db.prepare('DELETE FROM videos WHERE id = ?').bind(id),
        db.prepare('DELETE FROM profile_video_assignments WHERE video_id = ?').bind(id),
        db.prepare('DELETE FROM watch_events WHERE video_id = ?').bind(id),
      ]);
    }

    return new Response(JSON.stringify({ success: true, deleted_id: id }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error: any) {
    console.error('studio/videos DELETE error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

export const PATCH: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'PATCH', 'DELETE', 'OPTIONS'], isStateChanging: true });

  try {
    const body = await context.request.json().catch(() => ({}));
    const { id, status, category_id, file_verified } = body;

    if (!id) {
      return new Response(JSON.stringify({ error: 'id is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // Whitelist status values
    if (status !== undefined && !ALLOWED_STATUSES.has(status)) {
      return new Response(
        JSON.stringify({
          error: `Invalid status. Allowed values: ${Array.from(ALLOWED_STATUSES).join(', ')}`,
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    const db = await getDatabase(context);
    if (db) {
      // Verify video exists
      const video = await db.prepare('SELECT id FROM videos WHERE id = ?').bind(id).first();
      if (!video) {
        return new Response(JSON.stringify({ error: 'Video not found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }

      // Verify category_id exists if specified
      if (category_id !== undefined) {
        const cat = await db.prepare('SELECT id FROM categories WHERE id = ?').bind(category_id).first();
        if (!cat) {
          return new Response(JSON.stringify({ error: 'Invalid category_id: category does not exist' }), {
            status: 400,
            headers: { 'Content-Type': 'application/json', ...corsHeaders },
          });
        }
      }

      let query = 'UPDATE videos SET ';
      const updates: string[] = [];
      const values: any[] = [];

      if (status !== undefined) {
        updates.push('status = ?');
        values.push(status);
      }
      if (category_id !== undefined) {
        updates.push('category_id = ?');
        values.push(category_id);
      }
      if (file_verified !== undefined) {
        updates.push('file_verified = ?');
        values.push(file_verified ? 1 : 0);
      }

      if (updates.length > 0) {
        query += updates.join(', ') + ' WHERE id = ?';
        values.push(id);
        await db.prepare(query).bind(...values).run();
      }
    }

    return new Response(JSON.stringify({ success: true, updated_id: id }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error: any) {
    console.error('studio/videos PATCH error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

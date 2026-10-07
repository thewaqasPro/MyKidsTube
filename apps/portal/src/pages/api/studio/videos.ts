import type { APIRoute } from 'astro';
import { getDatabase, getDbData } from '../../../lib/db';

export const GET: APIRoute = async (context) => {
  try {
    const db = await getDatabase(context);
    if (db) {
      const res = await db.prepare('SELECT * FROM videos ORDER BY created_at DESC').all();
      return new Response(JSON.stringify(res.results || []), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const data = await getDbData(context);
    return new Response(JSON.stringify(data.videos), {
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

export const DELETE: APIRoute = async (context) => {
  try {
    const url = new URL(context.request.url);
    const id = url.searchParams.get('id');

    if (!id) {
      return new Response(JSON.stringify({ error: 'id parameter is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const db = await getDatabase(context);
    if (db) {
      await db.batch([
        db.prepare('DELETE FROM videos WHERE id = ?').bind(id),
        db.prepare('DELETE FROM profile_video_assignments WHERE video_id = ?').bind(id),
        db.prepare('DELETE FROM watch_events WHERE video_id = ?').bind(id),
      ]);
    }

    return new Response(JSON.stringify({ success: true, deleted_id: id }), {
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

export const PATCH: APIRoute = async (context) => {
  try {
    const body = await context.request.json();
    const { id, status, category_id, file_verified } = body;

    if (!id) {
      return new Response(JSON.stringify({ error: 'id is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const db = await getDatabase(context);
    if (db) {
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
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

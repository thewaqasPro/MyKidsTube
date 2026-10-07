import type { APIRoute } from 'astro';
import { getDatabase } from '../../../../lib/db';

export const POST: APIRoute = async (context) => {
  try {
    const body = await context.request.json().catch(() => ({}));
    const { pairing_code, profile_id = 'kids_all' } = body;

    if (!pairing_code) {
      return new Response(JSON.stringify({ error: 'Pairing code is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const db = await getDatabase(context);
    if (db) {
      const res = await db
        .prepare(
          "UPDATE devices SET status = 'paired', profile_id = ?, family_id = 'default_family' WHERE pairing_code = ?"
        )
        .bind(profile_id, pairing_code.trim())
        .run();

      if (res.meta.changes === 0) {
        return new Response(JSON.stringify({ error: 'Pairing code not found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' },
        });
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Device successfully paired!',
        pairing_code,
        profile_id,
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

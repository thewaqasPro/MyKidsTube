import type { APIRoute } from 'astro';
import { getDatabase } from '../../../../../lib/db';

export const GET: APIRoute = async (context) => {
  const { code } = context.params;
  if (!code) {
    return new Response(JSON.stringify({ error: 'Code required' }), { status: 400 });
  }

  const db = await getDatabase(context);
  if (!db) {
    return new Response(JSON.stringify({ status: 'paired' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const device: any = await db
      .prepare('SELECT * FROM devices WHERE pairing_code = ?')
      .bind(code)
      .first();

    if (!device) {
      return new Response(
        JSON.stringify({ status: 'not_found', error: 'Invalid pairing code' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    let profile = null;
    if (device.profile_id) {
      profile = await db
        .prepare('SELECT * FROM child_profiles WHERE id = ?')
        .bind(device.profile_id)
        .first();
    }

    return new Response(
      JSON.stringify({
        status: device.status,
        device_id: device.id,
        device_name: device.device_name,
        profile: profile || {
          id: 'kids_all',
          name: 'All Kids',
          avatar_icon: 'stars',
          age_bracket: 'all',
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

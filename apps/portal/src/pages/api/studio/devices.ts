import type { APIRoute } from 'astro';
import { getDatabase } from '../../../lib/db';
import { requireParent } from '../../../lib/parentAuth';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'OPTIONS'], isStateChanging: false });

  try {
    const db = await getDatabase(context);
    if (!db) {
      return new Response(JSON.stringify([]), {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const res: any = await db.prepare(`
      SELECT 
        d.id,
        d.device_name,
        d.pairing_code,
        d.status,
        d.created_at,
        d.profile_id,
        cp.name as profile_name,
        CASE WHEN d.auth_token IS NOT NULL THEN 1 ELSE 0 END as has_token
      FROM devices d
      LEFT JOIN child_profiles cp ON d.profile_id = cp.id
      ORDER BY d.created_at DESC
    `).all();

    return new Response(JSON.stringify(res.results || []), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error: any) {
    console.error('studio/devices GET error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

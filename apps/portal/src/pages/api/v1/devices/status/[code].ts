import type { APIRoute } from 'astro';
import { getDatabase } from '../../../../../lib/db';
import { checkRateLimit, createRateLimitResponse } from '../../../../../lib/rateLimit';
import { getCorsHeaders, handleOptions } from '../../../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'OPTIONS'], isStateChanging: false });

  // Rate-limit: 10 status checks/minute per IP
  const rateLimit = checkRateLimit(context.request, 10, 60000);
  if (!rateLimit.allowed) {
    return createRateLimitResponse();
  }

  const { code } = context.params;
  if (!code || typeof code !== 'string') {
    return new Response(JSON.stringify({ error: 'Code required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const cleanCode = code.trim();

  const db = await getDatabase(context);
  // Never fail open: if database binding is not available, fail closed with 500
  if (!db) {
    return new Response(
      JSON.stringify({ error: 'internal_error' }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  }

  try {
    const device: any = await db
      .prepare('SELECT * FROM devices WHERE pairing_code = ?')
      .bind(cleanCode)
      .first();

    // Unknown code - generic response, no oracle
    if (!device) {
      return new Response(
        JSON.stringify({ status: 'not_found', error: 'Invalid pairing code' }),
        { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    // Check expiry
    if (device.expires_at) {
      const expiresAt = new Date(device.expires_at).getTime();
      if (expiresAt <= Date.now() && device.status !== 'paired') {
        return new Response(
          JSON.stringify({ status: 'expired', error: 'Pairing code expired' }),
          { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
        );
      }
    }

    if (device.status !== 'paired') {
      return new Response(
        JSON.stringify({
          status: 'pending',
          device_id: device.id,
          device_name: device.device_name,
        }),
        {
          status: 200,
          headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', ...corsHeaders },
        }
      );
    }

    // Status is 'paired'
    let profile = null;
    if (device.profile_id) {
      profile = await db
        .prepare('SELECT id, name, avatar_icon, age_bracket FROM child_profiles WHERE id = ?')
        .bind(device.profile_id)
        .first();
    }

    // Deliver raw auth_token strictly ONCE, then clear from database
    const tokenToDeliver = device.raw_token_pending || null;
    if (tokenToDeliver) {
      await db
        .prepare('UPDATE devices SET raw_token_pending = NULL WHERE id = ?')
        .bind(device.id)
        .run();
    }

    return new Response(
      JSON.stringify({
        status: 'paired',
        device_id: device.id,
        device_name: device.device_name,
        auth_token: tokenToDeliver, // Only sent on the first poll after pairing
        profile: profile || {
          id: 'kids_all',
          name: 'All Kids',
          avatar_icon: 'stars',
          age_bracket: 'all',
        },
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-store',
          ...corsHeaders,
        },
      }
    );
  } catch (error: any) {
    console.error('v1/devices/status error:', error);
    return new Response(
      JSON.stringify({ error: 'internal_error' }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
};

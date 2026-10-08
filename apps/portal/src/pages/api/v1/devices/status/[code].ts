import type { APIRoute } from 'astro';
import { getDatabase } from '../../../../../lib/db';
import { hashToken } from '../../../../../lib/parentAuth';
import { checkRateLimit, createRateLimitResponse } from '../../../../../lib/rateLimit';
import { getCorsHeaders, handleOptions } from '../../../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'OPTIONS'], isStateChanging: false });

  // Rate-limit: 30 status checks/minute per IP
  const rateLimit = checkRateLimit(context.request, 30, 60000);
  if (!rateLimit.allowed) {
    return createRateLimitResponse();
  }

  const { code } = context.params;
  if (!code || typeof code !== 'string') {
    return new Response(JSON.stringify({ error: 'bad_request', message: 'Code required' }), {
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

    // Collapse expired-vs-unknown distinction to one generic 404 response to eliminate oracle
    const isExpired = device?.expires_at && new Date(device.expires_at).getTime() <= Date.now() && device.status !== 'paired';
    if (!device || isExpired) {
      return new Response(
        JSON.stringify({ error: 'not_found', message: 'Pairing code not found or expired' }),
        { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    // Validate Authorization header if provided
    const authHeader = context.request.headers.get('authorization') || '';
    let isHeaderAuthenticated = false;

    if (authHeader) {
      if (!authHeader.toLowerCase().startsWith('bearer ')) {
        return new Response(JSON.stringify({ error: 'unauthorized', message: 'Device authentication required' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }
      const token = authHeader.substring(7).trim();
      const tokenHash = await hashToken(token);
      if (!device.auth_token || tokenHash !== device.auth_token) {
        return new Response(JSON.stringify({ error: 'unauthorized', message: 'Invalid device auth token' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }
      isHeaderAuthenticated = true;
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

    // Status is 'paired': Atomically claim raw_token_pending strictly ONCE via UPDATE ... RETURNING id
    let claimedToken: string | null = null;
    if (device.raw_token_pending) {
      try {
        const claimResult: any = await db
          .prepare(
            'UPDATE devices SET raw_token_pending = NULL WHERE id = ? AND raw_token_pending = ? RETURNING id'
          )
          .bind(device.id, device.raw_token_pending)
          .first();

        if (claimResult && claimResult.id) {
          claimedToken = device.raw_token_pending;
        }
      } catch (claimErr) {
        console.warn('Atomic token claim error:', claimErr);
      }
    }

    // If neither authenticated by Authorization header nor claimed token in this poll:
    // Reject with 401 to prevent double delivery on concurrent polls
    if (!isHeaderAuthenticated && !claimedToken) {
      return new Response(
        JSON.stringify({
          error: 'unauthorized',
          message: 'Device authentication required',
        }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    let profile = null;
    if (device.profile_id) {
      profile = await db
        .prepare('SELECT id, name, avatar_icon, age_bracket FROM child_profiles WHERE id = ?')
        .bind(device.profile_id)
        .first();
    }

    return new Response(
      JSON.stringify({
        status: 'paired',
        device_id: device.id,
        device_name: device.device_name,
        auth_token: claimedToken, // Only sent to the single atomic claimant
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

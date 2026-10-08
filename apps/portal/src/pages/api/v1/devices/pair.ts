import type { APIRoute } from 'astro';
import { getDatabase } from '../../../../lib/db';
import { hashToken, requireParent } from '../../../../lib/parentAuth';
import { checkRateLimit, createRateLimitResponse } from '../../../../lib/rateLimit';
import { getCorsHeaders, handleOptions } from '../../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['POST', 'OPTIONS']);
};

export const POST: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['POST', 'OPTIONS'], isStateChanging: true });

  // Rate-limit: 10 attempts/minute per IP
  const rateLimit = checkRateLimit(context.request, 10, 60000);
  if (!rateLimit.allowed) {
    return createRateLimitResponse();
  }

  try {
    const body = (await context.request.json().catch(() => ({}))) as Record<string, unknown>;
    const rawCode = String(body.pairing_code || '').trim();
    const profileId = String(body.profile_id || 'kids_all').trim();
    const rawDeviceName = body.device_name ? String(body.device_name) : null;
    const sanitizedDeviceName = rawDeviceName
      ? rawDeviceName.replace(/[\x00-\x1F\x7F]/g, '').trim().slice(0, 64)
      : null;

    if (!rawCode) {
      return new Response(JSON.stringify({ error: 'Pairing code is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // Normalize code (e.g. ABC234 -> ABC-234, uppercase, trim)
    let normalizedCode = rawCode.toUpperCase().replace(/\s+/g, '');
    if (/^[A-Z0-9]{3}[A-Z0-9]{3}$/.test(normalizedCode)) {
      normalizedCode = normalizedCode.slice(0, 3) + '-' + normalizedCode.slice(3);
    }

    const db = await getDatabase(context);
    if (!db) {
      return new Response(JSON.stringify({ error: 'internal_error' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // 1. Validate that the profile exists
    const profileExists = await db
      .prepare('SELECT id FROM child_profiles WHERE id = ?')
      .bind(profileId)
      .first();

    if (!profileExists) {
      return new Response(JSON.stringify({ error: 'Selected child profile does not exist' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // 2. Fetch the device pairing record
    const device: any = await db
      .prepare('SELECT id, status, used, expires_at FROM devices WHERE pairing_code = ? OR pairing_code = ?')
      .bind(normalizedCode, rawCode)
      .first();

    if (!device) {
      // Unknown code - return generic error (no oracle)
      return new Response(JSON.stringify({ error: 'Invalid or expired pairing code' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // 3. Reject if already paired or used
    if (device.used === 1 || device.status === 'paired') {
      return new Response(JSON.stringify({ error: 'Pairing code has already been used' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // 4. Reject if expired
    if (device.expires_at) {
      const expiresAt = new Date(device.expires_at).getTime();
      if (expiresAt <= Date.now()) {
        return new Response(JSON.stringify({ error: 'Pairing code has expired' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }
    }

    // 5. Generate secure random auth_token for device
    const randomBytes = new Uint8Array(32);
    crypto.getRandomValues(randomBytes);
    const rawToken = 'tok_' + Array.from(randomBytes).map((b) => b.toString(16).padStart(2, '0')).join('');
    const tokenHash = await hashToken(rawToken);

    // 6. Update device row: set status=paired, used=1, store hash, stage raw token for one-time retrieval
    const updateQuery = sanitizedDeviceName
      ? `UPDATE devices SET status = 'paired', used = 1, profile_id = ?, family_id = 'default_family', auth_token = ?, raw_token_pending = ?, device_name = ? WHERE id = ? AND (used = 0 OR used IS NULL)`
      : `UPDATE devices SET status = 'paired', used = 1, profile_id = ?, family_id = 'default_family', auth_token = ?, raw_token_pending = ? WHERE id = ? AND (used = 0 OR used IS NULL)`;

    const bindArgs = sanitizedDeviceName
      ? [profileId, tokenHash, rawToken, sanitizedDeviceName, device.id]
      : [profileId, tokenHash, rawToken, device.id];

    const updateRes = await db.prepare(updateQuery).bind(...bindArgs).run();

    if (updateRes.meta.changes === 0) {
      return new Response(JSON.stringify({ error: 'Pairing code already used or invalid' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Device successfully paired!',
        pairing_code: rawCode,
        profile_id: profileId,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  } catch (error: any) {
    console.error('v1/devices/pair error:', error);
    return new Response(
      JSON.stringify({ error: 'internal_error' }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
};

import type { APIRoute } from 'astro';
import { getDatabase } from '../../../../lib/db';
import { getCorsHeaders, handleOptions } from '../../../../lib/cors';

function generateSecurePairingCode(): string {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const digits = '23456789';
  const randomBytes = new Uint8Array(6);
  crypto.getRandomValues(randomBytes);

  let p1 = '';
  for (let i = 0; i < 3; i++) {
    p1 += letters.charAt(randomBytes[i] % letters.length);
  }
  let p2 = '';
  for (let i = 3; i < 6; i++) {
    p2 += digits.charAt(randomBytes[i] % digits.length);
  }
  return `${p1}-${p2}`;
}

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['POST', 'OPTIONS']);
};

export const POST: APIRoute = async (context) => {
  const corsHeaders = getCorsHeaders(context.request, { methods: ['POST', 'OPTIONS'], isStateChanging: true });

  try {
    const body = await context.request.json().catch(() => ({}));
    const rawName = String(body.device_name || 'Kids Tablet');
    const sanitizedName = rawName.replace(/[\x00-\x1F\x7F]/g, '').trim().slice(0, 64) || 'Kids Tablet';

    const db = await getDatabase(context);
    const deviceId = 'dev_' + crypto.randomUUID().replace(/-/g, '').slice(0, 12);
    const pairingCode = generateSecurePairingCode();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 10 * 60 * 1000).toISOString();

    if (db) {
      await db
        .prepare(`
          INSERT INTO devices (id, device_name, pairing_code, status, expires_at, used, created_at)
          VALUES (?, ?, ?, 'pending', ?, 0, ?)
        `)
        .bind(deviceId, sanitizedName, pairingCode, expiresAt, now.toISOString())
        .run();
    }

    return new Response(
      JSON.stringify({
        device_id: deviceId,
        pairing_code: pairingCode,
        device_name: sanitizedName,
        status: 'pending',
        expires_in_seconds: 600,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  } catch (error: any) {
    console.error('v1/devices/register error:', error);
    return new Response(
      JSON.stringify({ error: 'internal_error' }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
};

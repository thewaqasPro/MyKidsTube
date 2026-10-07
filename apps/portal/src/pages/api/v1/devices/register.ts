import type { APIRoute } from 'astro';
import { getDatabase } from '../../../../lib/db';

function generatePairingCode(): string {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const digits = '23456789';
  let p1 = '';
  for (let i = 0; i < 3; i++) p1 += letters.charAt(Math.floor(Math.random() * letters.length));
  let p2 = '';
  for (let i = 0; i < 3; i++) p2 += digits.charAt(Math.floor(Math.random() * digits.length));
  return `${p1}-${p2}`;
}

export const POST: APIRoute = async (context) => {
  try {
    const body = await context.request.json().catch(() => ({}));
    const deviceName = body.device_name || 'Kids Device';
    const db = await getDatabase(context);

    const deviceId = 'dev_' + Math.random().toString(36).substring(2, 11);
    const pairingCode = generatePairingCode();
    const now = new Date().toISOString();

    if (db) {
      await db
        .prepare('INSERT INTO devices (id, device_name, pairing_code, status, created_at) VALUES (?, ?, ?, ?, ?)')
        .bind(deviceId, deviceName, pairingCode, 'pending', now)
        .run();
    }

    return new Response(
      JSON.stringify({
        device_id: deviceId,
        pairing_code: pairingCode,
        device_name: deviceName,
        status: 'pending',
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

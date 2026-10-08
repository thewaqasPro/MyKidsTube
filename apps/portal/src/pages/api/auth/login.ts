import type { APIRoute } from 'astro';
import { getDatabase } from '../../../lib/db';
import { createParentSession, buildSessionCookie } from '../../../lib/parentAuth';
import { checkRateLimit, createRateLimitResponse } from '../../../lib/rateLimit';

export const POST: APIRoute = async (context) => {
  // 1. Rate-limit PIN attempts: 10 attempts per minute per IP
  const rateLimit = checkRateLimit(context.request, 10, 60000);
  const clientIp =
    context.request.headers.get('CF-Connecting-IP') ||
    context.request.headers.get('x-real-ip') ||
    context.request.headers.get('x-forwarded-for')?.split(',')[0].trim() ||
    'anonymous_client';

  if (!rateLimit.allowed) {
    console.error(
      `[SECURITY ALERT] Rate limit exceeded on /api/auth/login for IP: ${clientIp}. Brute-force lockout triggered (429).`
    );
    return createRateLimitResponse();
  }

  try {
    const body = (await context.request.json().catch(() => ({}))) as Record<string, unknown>;
    const pin = String(body.pin || '').trim();

    if (!pin) {
      return new Response(JSON.stringify({ error: 'PIN is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const db = await getDatabase(context);
    let expectedPin = '1234';

    if (db) {
      try {
        const res: any = await db
          .prepare("SELECT value FROM admin_settings WHERE key = 'parent_pin'")
          .first();
        if (res && res.value !== undefined && res.value !== null) {
          expectedPin = String(res.value);
        }
      } catch (dbErr: any) {
        console.warn('admin_settings table query warning (auto-initializing if missing):', dbErr);
        try {
          await db.prepare("CREATE TABLE IF NOT EXISTS admin_settings (key TEXT PRIMARY KEY, value TEXT)").run();
          await db.prepare("INSERT OR IGNORE INTO admin_settings (key, value) VALUES ('parent_pin', '1234')").run();
          const res: any = await db.prepare("SELECT value FROM admin_settings WHERE key = 'parent_pin'").first();
          if (res && res.value) {
            expectedPin = String(res.value);
          }
        } catch (initErr) {
          console.error('Failed to auto-initialize admin_settings:', initErr);
          expectedPin = '1234';
        }
      }
    }

    // Strictly match expected PIN - no hardcoded '1234' fallback when custom PIN is set
    if (pin !== expectedPin) {
      console.warn(
        `[SECURITY WARNING] Incorrect Parent PIN attempt from IP: ${clientIp}. Remaining attempts: ${rateLimit.remaining}`
      );
      if (rateLimit.remaining <= 3) {
        console.warn(
          `[SECURITY ALERT] Elevated failed login volume detected from IP: ${clientIp}. Approaching lockout threshold.`
        );
      }
      return new Response(JSON.stringify({ error: 'Incorrect Parent PIN' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Create a real server-side session with 256-bit token & D1 storage
    let sessionToken: string;
    try {
      sessionToken = await createParentSession(db);
    } catch (sessionErr: any) {
      console.error('Session creation failed:', sessionErr);
      return new Response(
        JSON.stringify({ error: 'internal_error' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const cookieHeader = buildSessionCookie(sessionToken);
    console.log(`[AUTH] Successful Parent PIN login from IP: ${clientIp}`);

    return new Response(
      JSON.stringify({ success: true, message: 'Parent authenticated successfully' }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Set-Cookie': cookieHeader,
        },
      }
    );
  } catch (error: any) {
    console.error('Login error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

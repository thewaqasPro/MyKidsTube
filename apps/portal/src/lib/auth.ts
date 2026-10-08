import { betterAuth } from 'better-auth';
import { drizzleAdapter } from '@better-auth/drizzle-adapter';
import { bearer } from 'better-auth/plugins';
import { passkey } from '@better-auth/passkey';
import { eq } from 'drizzle-orm';
import { getDrizzle } from '../db';
import * as schema from '../db/schema';
import { getEnv } from './env';

export function getAuth(env: any, request?: Request) {
  if (!env?.DB) {
    throw new Error('Cloudflare D1 database binding "DB" is missing.');
  }

  const drizzleDb = getDrizzle(env.DB);
  const origin = request ? new URL(request.url).origin : (env.BETTER_AUTH_URL || 'http://localhost:4321');
  const hostname = request ? new URL(request.url).hostname : 'localhost';

  return betterAuth({
    database: drizzleAdapter(drizzleDb, {
      provider: 'sqlite',
      schema,
    }),
    secret: env.BETTER_AUTH_SECRET || 'kidstube_dev_secret_key_change_in_production_32bytes',
    baseURL: env.BETTER_AUTH_URL || origin,
    emailAndPassword: {
      enabled: true,
      autoSignIn: true,
    },
    user: {
      additionalFields: {
        role: {
          type: 'string',
          defaultValue: 'parent',
        },
        pinHash: {
          type: 'string',
          required: false,
        },
      },
    },
    plugins: [
      bearer(),
      passkey({
        rpID: hostname,
        rpName: 'KidsTube Parent Studio',
        origin: origin,
      }),
    ],
    session: {
      expiresIn: 60 * 60 * 24 * 7, // 7 days
      updateAge: 60 * 60 * 24,      // 24 hours
      cookieCache: {
        enabled: true,
        maxAge: 5 * 60,            // 5 minutes
      },
    },
  });
}

async function hashToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

function extractLegacyToken(request: Request): string | null {
  const authHeader = request.headers.get('authorization') || '';
  if (authHeader.toLowerCase().startsWith('bearer ')) {
    const token = authHeader.substring(7).trim();
    if (token.length > 0) return token;
  }
  const cookieHeader = request.headers.get('cookie') || '';
  const match = cookieHeader.match(/(?:^|;\s*)kidstube_parent_session=([^;]+)/);
  if (!match) return null;
  return decodeURIComponent(match[1].trim());
}

/**
 * Universal session verifier:
 * 1. Checks modern Better Auth session (Cookie or Bearer).
 * 2. Falls back to legacy parent_sessions & devices table for paired tablets / VPS.
 */
export async function getAuthenticatedParent(context: any): Promise<{ user: any; session: any } | null> {
  const env = await getEnv(context);
  if (!env?.DB) return null;

  const request: Request = context.request;

  try {
    const auth = getAuth(env, request);
    const sessionRes = await auth.api.getSession({
      headers: request.headers,
    });

    if (sessionRes?.user && sessionRes?.session) {
      return {
        user: sessionRes.user,
        session: sessionRes.session,
      };
    }
  } catch (authErr) {
    console.warn('Better Auth session inspection warning:', authErr);
  }

  // Fallback: Check legacy parent_sessions table or paired device token using Drizzle
  try {
    const token = extractLegacyToken(request);
    if (token && token !== 'authenticated') {
      const tokenHash = await hashToken(token);
      const drizzleDb = getDrizzle(env.DB);

      // Check parent_sessions
      const sessionRow = await drizzleDb
        .select()
        .from(schema.parentSessions)
        .where(eq(schema.parentSessions.tokenHash, tokenHash))
        .get();

      if (sessionRow && sessionRow.expiresAt) {
        const expiresAt = new Date(sessionRow.expiresAt).getTime();
        if (expiresAt > Date.now()) {
          return {
            user: { id: 'legacy_parent', name: 'Parent', email: 'parent@kidstube.local', role: 'parent' },
            session: { id: 'legacy_session', userId: 'legacy_parent' },
          };
        }
      }

      // Check devices
      const deviceRow = await drizzleDb
        .select()
        .from(schema.devices)
        .where(eq(schema.devices.authToken, tokenHash))
        .get();

      if (deviceRow && deviceRow.status === 'paired') {
        return {
          user: { id: deviceRow.id, name: deviceRow.deviceName, email: `${deviceRow.id}@device.kidstube.local`, role: 'device' },
          session: { id: `device_${deviceRow.id}`, userId: deviceRow.id },
        };
      }
    }
  } catch (legacyErr) {
    console.warn('Legacy session inspection error:', legacyErr);
  }

  return null;
}

/**
 * Require parent auth route guard
 */
export async function requireAuthenticatedParent(context: any): Promise<Response | null> {
  const auth = await getAuthenticatedParent(context);
  if (!auth) {
    return new Response(JSON.stringify({ error: 'unauthorized', message: 'Parent authentication required' }), {
      status: 401,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-store',
      },
    });
  }
  return null;
}

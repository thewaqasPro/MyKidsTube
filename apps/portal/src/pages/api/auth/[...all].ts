import type { APIRoute } from 'astro';
import { getAuth } from '../../../lib/auth';
import { getEnv } from '../../../lib/env';

/**
 * Whitelist of permitted subpaths under /api/auth/*.
 * Only explicitly audited flows (login, logout, session verification, passkey auth)
 * are allowed. All self-registration and unexpected administrative routes are rejected.
 */
const ALLOWED_EXACT_FLOWS = new Set([
  'sign-in',
  'sign-in/email',
  'sign-out',
  'get-session',
  'session',
  'ok',
  'csrf',
]);

const ALLOWED_PREFIXES = [
  'passkey/',
];

export const ALL: APIRoute = async (context) => {
  const url = new URL(context.request.url);
  const rawPath = context.params.all || url.pathname.replace(/^\/api\/auth\/?/, '');
  const subpath = (Array.isArray(rawPath) ? rawPath.join('/') : String(rawPath))
    .replace(/^\/+|\/+$/g, '')
    .toLowerCase();

  // 1. Explicitly block all self-registration endpoints
  if (subpath.startsWith('sign-up') || subpath.includes('sign-up')) {
    return new Response(
      JSON.stringify({
        error: 'signup_disabled',
        message: 'Public registration is disabled. Parent accounts must be invited or provisioned by an administrator.',
      }),
      {
        status: 404,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-store',
        },
      }
    );
  }

  // 2. Audit against allowed flow whitelist
  const isAllowed =
    ALLOWED_EXACT_FLOWS.has(subpath) ||
    ALLOWED_PREFIXES.some((prefix) => subpath.startsWith(prefix));

  if (!isAllowed) {
    return new Response(
      JSON.stringify({
        error: 'not_found',
        message: `Auth route "${subpath}" is disabled or not found.`,
      }),
      {
        status: 404,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-store',
        },
      }
    );
  }

  const env = await getEnv(context);
  if (!env?.DB) {
    return new Response(JSON.stringify({ error: 'Database binding missing' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const auth = getAuth(env, context.request);
    return await auth.handler(context.request);
  } catch (err: any) {
    console.error('Better Auth route handler error:', err);
    return new Response(JSON.stringify({ error: 'auth_handler_error', details: err?.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

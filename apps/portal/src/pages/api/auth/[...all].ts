import type { APIRoute } from 'astro';
import { getAuth } from '../../../lib/auth';
import { getEnv } from '../../../lib/env';

export const ALL: APIRoute = async (context) => {
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

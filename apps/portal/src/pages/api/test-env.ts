import type { APIRoute } from 'astro';

export const GET: APIRoute = async (context) => {
  const locals = context.locals as any;
  const runtime = locals?.runtime;
  const env = runtime?.env || (locals as any)?.cloudflare?.env || (locals as any)?.env;

  const db = env?.DB;
  let dbWorking = false;
  let count = 0;
  let error = null;

  if (db) {
    try {
      const res = await db.prepare('SELECT COUNT(*) as count FROM videos').first();
      count = res?.count;
      dbWorking = true;
    } catch (e: any) {
      error = e.message;
    }
  }

  return new Response(
    JSON.stringify({
      localsKeys: Object.keys(locals || {}),
      runtimeKeys: runtime ? Object.keys(runtime) : null,
      envKeys: env ? Object.keys(env) : null,
      hasDB: !!db,
      dbWorking,
      count,
      error,
    }, null, 2),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    }
  );
};

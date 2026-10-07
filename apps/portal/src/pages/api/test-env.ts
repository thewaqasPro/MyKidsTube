import type { APIRoute } from 'astro';

export const GET: APIRoute = async (context) => {
  try {
    const cfWorkers = await import('cloudflare:workers').catch(() => null);
    const cfEnv = (cfWorkers as any)?.env;

    const locals = (context.locals as any) || {};

    return new Response(
      JSON.stringify(
        {
          cfEnvKeys: cfEnv ? Object.keys(cfEnv) : null,
          hasDB: !!cfEnv?.DB,
          hasR2: !!cfEnv?.R2,
          localsKeys: Object.keys(locals),
        },
        null,
        2
      ),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message, stack: err.stack }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

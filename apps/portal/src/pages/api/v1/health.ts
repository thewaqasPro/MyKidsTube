import type { APIRoute } from 'astro';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'OPTIONS']);
};

export const GET: APIRoute = async ({ request }) => {
  const corsHeaders = getCorsHeaders(request, { methods: ['GET', 'OPTIONS'], isStateChanging: false });
  return new Response(
    JSON.stringify({
      status: 'ok',
      service: 'MyKidsTube Cloudflare Edge API',
      timestamp: new Date().toISOString(),
    }),
    {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    }
  );
};

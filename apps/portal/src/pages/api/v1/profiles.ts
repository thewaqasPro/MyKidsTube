import type { APIRoute } from 'astro';
import { getDbData } from '../../../lib/db';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'OPTIONS'], isStateChanging: false });

  try {
    const data = await getDbData(context);
    return new Response(JSON.stringify(data.profiles || []), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'private, max-age=60',
        ...corsHeaders,
      },
    });
  } catch (error: any) {
    console.error('v1/profiles error:', error);
    return new Response(
      JSON.stringify({ error: 'internal_error' }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    );
  }
};

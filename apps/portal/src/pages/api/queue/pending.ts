import type { APIRoute } from 'astro';
import { getPendingVideos } from '../../../lib/db';
import { requireParent } from '../../../lib/parentAuth';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'OPTIONS'], isStateChanging: false });

  try {
    const url = new URL(context.request.url);
    const format = url.searchParams.get('format');
    const pending = await getPendingVideos(context);

    if (format === 'txt') {
      const urls = pending
        .map((v) => v.source_url || `https://www.youtube.com/watch?v=${v.youtube_id || v.id}`)
        .filter(Boolean)
        .join('\n');

      return new Response(urls, {
        status: 200,
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          'Content-Disposition': 'attachment; filename="links.txt"',
          'Cache-Control': 'no-store',
          ...corsHeaders,
        },
      });
    }

    return new Response(
      JSON.stringify({
        count: pending.length,
        videos: pending,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  } catch (error: any) {
    console.error('queue/pending error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

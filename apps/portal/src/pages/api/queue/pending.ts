import type { APIRoute } from 'astro';
import { getPendingVideos } from '../../../lib/db';

export const GET: APIRoute = async (context) => {
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
        },
      });
    }

    return new Response(JSON.stringify({
      count: pending.length,
      videos: pending,
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

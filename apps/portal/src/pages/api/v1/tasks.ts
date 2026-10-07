import type { APIRoute } from 'astro';
import { getPendingVideos } from '../../../lib/db';

export const GET: APIRoute = async (context) => {
  try {
    const pending = await getPendingVideos(context);
    return new Response(JSON.stringify(pending), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};

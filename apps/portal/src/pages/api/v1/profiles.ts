import type { APIRoute } from 'astro';
import { getDbData } from '../../../lib/db';

export const GET: APIRoute = async (context) => {
  try {
    const data = await getDbData(context);
    return new Response(JSON.stringify(data.profiles || []), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300',
      },
    });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};

import type { APIRoute } from 'astro';
import { getStudioStats } from '../../../lib/db';

export const GET: APIRoute = async (context) => {
  try {
    const stats = await getStudioStats(context);
    return new Response(JSON.stringify(stats), {
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

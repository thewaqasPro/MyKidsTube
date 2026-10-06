import type { APIRoute } from 'astro';
import { API_BASE } from '../../lib/constants';

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();
    const res = await fetch(`${API_BASE}/api/v1/ingest/url`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    const data = await res.json();
    return new Response(JSON.stringify(data), {
      status: res.status,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message || 'Ingestion service unreachable' }),
      { status: 502, headers: { 'Content-Type': 'application/json' } }
    );
  }
};

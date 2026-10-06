import type { APIRoute } from 'astro';
import { API_BASE } from '../../lib/constants';

export const GET: APIRoute = async () => {
  try {
    const res = await fetch(`${API_BASE}/api/v1/cookies/status`);
    const data = await res.json();
    return new Response(JSON.stringify(data), {
      status: res.status,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ configured: false, valid_cookies_count: 0 }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();
    const res = await fetch(`${API_BASE}/api/v1/cookies/upload`, {
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
      JSON.stringify({ error: error.message || 'Cookies service unreachable' }),
      { status: 502, headers: { 'Content-Type': 'application/json' } }
    );
  }
};

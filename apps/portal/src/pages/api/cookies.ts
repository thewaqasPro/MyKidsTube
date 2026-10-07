import type { APIRoute } from 'astro';
import { API_BASE } from '../../lib/constants';
import { requireParent } from '../../lib/parentAuth';
import { getCorsHeaders, handleOptions } from '../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'POST', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'POST', 'OPTIONS'], isStateChanging: false });

  try {
    const res = await fetch(`${API_BASE}/api/v1/cookies/status`);
    const data = await res.json();
    return new Response(JSON.stringify(data), {
      status: res.status,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error: any) {
    console.error('cookies status fetch error:', error);
    return new Response(
      JSON.stringify({ configured: false, valid_cookies_count: 0 }),
      { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
};

export const POST: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'POST', 'OPTIONS'], isStateChanging: true });

  try {
    const body = await context.request.json().catch(() => ({}));
    const res = await fetch(`${API_BASE}/api/v1/cookies/upload`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    const data = await res.json();
    return new Response(JSON.stringify(data), {
      status: res.status,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error: any) {
    console.error('cookies upload error:', error);
    return new Response(
      JSON.stringify({ error: 'internal_error' }),
      { status: 502, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
};

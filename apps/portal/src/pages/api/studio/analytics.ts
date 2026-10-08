import type { APIRoute } from 'astro';
import { getDatabase } from '@/lib/db';
import { requireParent } from '@/lib/parentAuth';
import { getCorsHeaders, handleOptions } from '@/lib/cors';
import { AnalyticsService } from '@/features/analytics/analytics.service';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, {
    methods: ['GET', 'OPTIONS'],
    isStateChanging: false,
  });

  const db = await getDatabase(context);
  if (!db) {
    return new Response(JSON.stringify({ error: 'database_unavailable' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  try {
    const url = new URL(context.request.url);
    const deviceId = url.searchParams.get('device_id') || 'all';
    const profileId = url.searchParams.get('profile_id') || 'all';
    const range = url.searchParams.get('range') || '7d';

    const report = await AnalyticsService.getAnalyticsReport(db, {
      deviceId,
      profileId,
      range,
    });

    return new Response(JSON.stringify(report), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error) {
    console.error('studio/analytics GET error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

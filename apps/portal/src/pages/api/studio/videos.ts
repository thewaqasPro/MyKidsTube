import type { APIRoute } from 'astro';
import { requireParent } from '@/lib/parentAuth';
import { getCorsHeaders, handleOptions } from '@/lib/cors';
import { getDrizzleDb } from '@/db';
import { CatalogService } from '@/features/catalog/catalog.service';

const ALLOWED_STATUSES = new Set(['pending_download', 'ready', 'error']);

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, {
    methods: ['GET', 'PATCH', 'DELETE', 'OPTIONS'],
    isStateChanging: false,
  });

  const drizzleDb = await getDrizzleDb(context);
  if (!drizzleDb) {
    return new Response(JSON.stringify({ error: 'Database unavailable' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  try {
    const videos = await CatalogService.listVideos(drizzleDb);
    return new Response(JSON.stringify(videos), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error) {
    console.error('studio/videos GET error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

export const POST: APIRoute = async (context) => {
  return DELETE(context);
};

export const DELETE: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, {
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    isStateChanging: true,
  });

  try {
    const url = new URL(context.request.url);
    const queryId = url.searchParams.get('id');
    const queryIds = url.searchParams.get('ids');

    let ids: string[] = [];
    if (queryIds) {
      ids = queryIds.split(',').map((s) => s.trim()).filter(Boolean);
    } else if (queryId) {
      ids = [queryId.trim()];
    } else {
      const body = (await context.request.json().catch(() => ({}))) as Record<string, any>;
      if (Array.isArray(body.ids)) {
        ids = body.ids.map((s: unknown) => String(s).trim()).filter(Boolean);
      } else if (body.id) {
        ids = [String(body.id).trim()];
      }
    }

    if (ids.length === 0) {
      return new Response(JSON.stringify({ error: 'id or ids parameter is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    if (ids.length > 100) {
      return new Response(JSON.stringify({ error: 'Maximum 100 videos can be deleted at once' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const drizzleDb = await getDrizzleDb(context);
    if (!drizzleDb) {
      return new Response(JSON.stringify({ error: 'Database unavailable' }), {
        status: 503,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const res = await CatalogService.deleteVideos(drizzleDb, ids, context);

    return new Response(
      JSON.stringify({
        success: true,
        message: `Successfully deleted ${res.deletedCount} video(s) from catalog`,
        deleted_ids: res.deletedIds,
        vps_cleanup: res.vpsCleanup,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  } catch (error) {
    console.error('studio/videos DELETE error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

export const PATCH: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, {
    methods: ['GET', 'PATCH', 'DELETE', 'OPTIONS'],
    isStateChanging: true,
  });

  try {
    const body = (await context.request.json().catch(() => ({}))) as Record<string, any>;
    const id = String(body.id || '').trim();
    const status = String(body.status || '').trim() as any;

    if (!id || !status) {
      return new Response(JSON.stringify({ error: 'id and status are required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    if (!ALLOWED_STATUSES.has(status)) {
      return new Response(JSON.stringify({ error: `Invalid status. Allowed: ${[...ALLOWED_STATUSES].join(', ')}` }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const drizzleDb = await getDrizzleDb(context);
    if (!drizzleDb) {
      return new Response(JSON.stringify({ error: 'Database unavailable' }), {
        status: 503,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    await CatalogService.updateVideoStatus(drizzleDb, id, status);

    return new Response(JSON.stringify({ success: true, message: `Status updated to ${status}` }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error) {
    console.error('studio/videos PATCH error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

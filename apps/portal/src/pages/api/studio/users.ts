import type { APIRoute } from 'astro';
import { getDatabase } from '../../../lib/db';
import { requireParent } from '../../../lib/parentAuth';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'POST', 'OPTIONS']);
};

/**
 * GET /api/studio/users
 * Lists users and their current authorization roles.
 * Protected: requires active parent session (role === 'parent').
 */
export const GET: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'OPTIONS'], isStateChanging: false });

  try {
    const db = await getDatabase(context);
    if (!db) {
      return new Response(JSON.stringify({ users: [] }), {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const res: any = await db
      .prepare('SELECT id, name, email, email_verified, role, created_at, updated_at FROM user ORDER BY created_at DESC')
      .all();

    return new Response(JSON.stringify({ users: res.results || [] }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error: any) {
    console.error('studio/users GET error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

/**
 * POST /api/studio/users
 * Promotes or updates a user's role (e.g. promoting 'unapproved' to 'parent').
 * Protected: only an existing authenticated parent can promote.
 */
export const POST: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['POST', 'OPTIONS'], isStateChanging: true });

  try {
    const body = (await context.request.json().catch(() => ({}))) as Record<string, unknown>;
    const userId = String(body.userId || '').trim();
    const newRole = String(body.role || '').trim().toLowerCase();

    if (!userId) {
      return new Response(JSON.stringify({ error: 'userId is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const VALID_ROLES = ['parent', 'unapproved', 'device'];
    if (!VALID_ROLES.includes(newRole)) {
      return new Response(JSON.stringify({ error: `Invalid role. Allowed roles: ${VALID_ROLES.join(', ')}` }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const db = await getDatabase(context);
    if (!db) {
      return new Response(JSON.stringify({ error: 'internal_error' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const existingUser: any = await db
      .prepare('SELECT id, name, email, role FROM user WHERE id = ?')
      .bind(userId)
      .first();

    if (!existingUser) {
      return new Response(JSON.stringify({ error: 'User not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const now = Math.floor(Date.now() / 1000);
    await db
      .prepare('UPDATE user SET role = ?, updated_at = ? WHERE id = ?')
      .bind(newRole, now, userId)
      .run();

    return new Response(
      JSON.stringify({
        success: true,
        user: {
          id: userId,
          email: existingUser.email,
          role: newRole,
        },
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  } catch (error: any) {
    console.error('studio/users POST error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

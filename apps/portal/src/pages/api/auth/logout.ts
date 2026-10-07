import type { APIRoute } from 'astro';
import { getDatabase } from '../../../lib/db';
import { destroyParentSession, buildClearSessionCookie } from '../../../lib/parentAuth';

export const POST: APIRoute = async (context) => {
  try {
    const db = await getDatabase(context);
    await destroyParentSession(context.request, db);

    return new Response(
      JSON.stringify({ success: true, message: 'Logged out successfully' }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Set-Cookie': buildClearSessionCookie(),
        },
      }
    );
  } catch (error: any) {
    console.error('Logout error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

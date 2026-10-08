import type { APIRoute } from 'astro';
import { requireAuthenticatedDevice, getAuthenticatedDevice } from '../../../../lib/auth';
import { getCorsHeaders, handleOptions } from '../../../../lib/cors';
import { getDrizzleDb } from '../../../../db';
import { devices, childProfiles } from '../../../../db/schema';
import { eq } from 'drizzle-orm';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const authErr = await requireAuthenticatedDevice(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'OPTIONS'], isStateChanging: false });
  const auth = await getAuthenticatedDevice(context);
  if (!auth) {
    return new Response(JSON.stringify({ error: 'unauthorized', message: 'Device authentication required' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const { id } = context.params;
  if (!id || typeof id !== 'string') {
    return new Response(JSON.stringify({ error: 'Device ID required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // Device can only query its own info
  if (auth.user.id !== id) {
    return new Response(JSON.stringify({ error: 'unauthorized', message: 'Access denied' }), {
      status: 403,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const drizzleDb = await getDrizzleDb(context);
  if (!drizzleDb) {
    return new Response(JSON.stringify({ error: 'database_unavailable' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  try {
    const device = await drizzleDb
      .select({
        id: devices.id,
        device_name: devices.deviceName,
        status: devices.status,
        profile_id: devices.profileId,
        created_at: devices.createdAt,
        profile_name: childProfiles.name,
      })
      .from(devices)
      .leftJoin(childProfiles, eq(devices.profileId, childProfiles.id))
      .where(eq(devices.id, id))
      .get();

    if (!device) {
      return new Response(JSON.stringify({ error: 'not_found', message: 'Device not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    return new Response(JSON.stringify(device), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (error: any) {
    console.error('v1/devices/[id] GET error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

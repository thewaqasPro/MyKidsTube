import type { APIRoute } from 'astro';
import { getDrizzleDb } from '../../../db';
import { adminSettings } from '../../../db/schema/devices';
import { requireParent } from '../../../lib/parentAuth';
import { eq } from 'drizzle-orm';

export const GET: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const drizzleDb = await getDrizzleDb(context);
  if (!drizzleDb) {
    return new Response(JSON.stringify({ error: 'Database unavailable' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const row = await drizzleDb
      .select()
      .from(adminSettings)
      .where(eq(adminSettings.key, 'parent_pin'))
      .get();

    return new Response(
      JSON.stringify({
        hasCustomPin: Boolean(row?.value && row.value !== '1234'),
        pinLength: row?.value?.length || 4,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error: any) {
    console.error('Error reading parent PIN status:', error);
    return new Response(JSON.stringify({ error: 'Failed to read PIN status' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

export const POST: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const drizzleDb = await getDrizzleDb(context);
  if (!drizzleDb) {
    return new Response(JSON.stringify({ error: 'Database unavailable' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const body = (await context.request.json().catch(() => ({}))) as Record<string, unknown>;
    const pin = String(body.pin || '').trim();

    if (!pin || !/^\d{4,6}$/.test(pin)) {
      return new Response(
        JSON.stringify({ error: 'PIN must be between 4 and 6 digits (numbers only).' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Upsert parent_pin using Drizzle ORM
    await drizzleDb
      .insert(adminSettings)
      .values({
        key: 'parent_pin',
        value: pin,
      })
      .onConflictDoUpdate({
        target: adminSettings.key,
        set: { value: pin },
      });

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Parent PIN updated successfully.',
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error: any) {
    console.error('Failed to update parent PIN:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to update PIN in database.' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};

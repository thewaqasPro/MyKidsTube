import { eq } from 'drizzle-orm';
import type { DrizzleDb } from '@/db';
import * as schema from '@/db/schema';

export class DevicesRepository {
  static async getAllDevices(db: DrizzleDb) {
    const rows = await db
      .select({
        id: schema.devices.id,
        familyId: schema.devices.familyId,
        profileId: schema.devices.profileId,
        deviceName: schema.devices.deviceName,
        pairingCode: schema.devices.pairingCode,
        status: schema.devices.status,
        authToken: schema.devices.authToken,
        createdAt: schema.devices.createdAt,
        expiresAt: schema.devices.expiresAt,
        profileName: schema.childProfiles.name,
      })
      .from(schema.devices)
      .leftJoin(schema.childProfiles, eq(schema.devices.profileId, schema.childProfiles.id));

    return rows.map((d) => ({
      id: d.id,
      device_name: d.deviceName,
      pairing_code: d.pairingCode,
      status: d.status,
      profile_name: d.profileName || 'All Kids',
      has_token: Boolean(d.authToken),
      created_at: d.createdAt,
    }));
  }

  static async deleteDeviceById(db: DrizzleDb, id: string): Promise<boolean> {
    const res = await db
      .delete(schema.devices)
      .where(eq(schema.devices.id, id));
    return Boolean(res);
  }

  static async getAdminSetting(db: DrizzleDb, key: string): Promise<string | null> {
    const row = await db
      .select()
      .from(schema.adminSettings)
      .where(eq(schema.adminSettings.key, key))
      .get();
    return row?.value ?? null;
  }

  static async setAdminSetting(db: DrizzleDb, key: string, value: string): Promise<void> {
    await db
      .insert(schema.adminSettings)
      .values({ key, value })
      .onConflictDoUpdate({
        target: schema.adminSettings.key,
        set: { value },
      });
  }
}

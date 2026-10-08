import { drizzle } from 'drizzle-orm/d1';
import * as schema from './schema';

import { getEnv } from '../lib/env';

export type DrizzleDb = ReturnType<typeof drizzle<typeof schema>>;

export function getDrizzle(d1: D1Database): DrizzleDb {
  return drizzle(d1, { schema });
}

export async function getDrizzleDb(context?: any): Promise<DrizzleDb | null> {
  try {
    const env = await getEnv(context);
    if (env?.DB) {
      return getDrizzle(env.DB);
    }
  } catch {
    // Expected in local Node environment without bindings
  }

  return null;
}

export * from './schema';

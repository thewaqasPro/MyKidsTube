import { getAppEnv, type AppEnv } from '../bindings/env';

export async function getEnv(context?: unknown): Promise<AppEnv | null> {
  return getAppEnv(context);
}

export type { AppEnv };

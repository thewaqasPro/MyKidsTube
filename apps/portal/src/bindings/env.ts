/**
 * Cloudflare Edge Environment Bindings
 * Strictly typed runtime environment definitions for D1, KV, Images, and Secrets.
 */

export interface AppEnv {
  DB: D1Database;
  BETTER_AUTH_SECRET?: string;
  BETTER_AUTH_URL?: string;
  VPS_API_URL?: string;
  VPS_API_KEY?: string;
  VPS_CLEANUP_SECRET?: string;
  IMAGES?: unknown;
  SESSION?: unknown;
  [key: string]: unknown;
}

/**
 * Safely resolves Cloudflare Workers environment bindings across
 * Astro production edge workers and local Miniflare dev environments.
 */
export async function getAppEnv(context?: unknown): Promise<AppEnv | null> {
  // 1. Cloudflare Workers module import (workerd runtime)
  try {
    const cf = await import('cloudflare:workers').catch(() => null);
    if ((cf as any)?.env?.DB) {
      return (cf as any).env as AppEnv;
    }
  } catch {
    // Expected outside workerd runtime
  }

  // 2. Astro context bindings (locals.cloudflare or locals.env)
  try {
    const locals = (context as any)?.locals;
    if (locals?.cloudflare?.env?.DB) {
      return locals.cloudflare.env as AppEnv;
    }
    if (locals?.env?.DB) {
      return locals.env as AppEnv;
    }
  } catch {
    // Expected when locals are undefined
  }

  return null;
}

import { API_BASE } from './constants';

export interface VpsCleanupResult {
  success: boolean;
  deleted_count?: number;
  deleted_ids?: string[];
  deleted_files?: string[];
  freed_bytes?: number;
  error?: string;
}

/**
 * Triggers deletion of self-hosted video and thumbnail files on the VPS storage.
 * Gracefully handles network timeouts and unreachable VPS without throwing.
 */
export async function cleanupVpsMedia(ids: string[], context?: any): Promise<VpsCleanupResult> {
  if (!ids || ids.length === 0) {
    return { success: true, deleted_count: 0 };
  }

  // Retrieve secret from Cloudflare Worker runtime environment
  const locals = context?.locals as any;
  const runtimeEnv = locals?.runtime?.env || locals?.cloudflare?.env || locals?.env;
  const secret =
    runtimeEnv?.VPS_CLEANUP_SECRET ||
    (typeof process !== 'undefined' && process.env?.VPS_CLEANUP_SECRET) ||
    'mykidstube_default_secret_2026';

  const vpsUrl = `${API_BASE}/api/storage/cleanup`;

  try {
    const res = await fetch(vpsUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Media-Secret': secret,
      },
      body: JSON.stringify({ ids }),
      signal: AbortSignal.timeout(6000), // 6s timeout to prevent hanging the request
    });

    if (res.ok) {
      const data: any = await res.json().catch(() => ({}));
      console.log(`[VPS Cleanup] Cleaned ${data.deleted_count || 0} file(s), freed ${data.freed_bytes || 0} bytes on VPS`);
      return {
        success: true,
        deleted_count: data.deleted_count || 0,
        deleted_ids: data.deleted_ids || [],
        freed_bytes: data.freed_bytes || 0,
      };
    } else {
      const errText = await res.text().catch(() => '');
      console.warn(`[VPS Cleanup] VPS responded with status ${res.status}: ${errText}`);
      return {
        success: false,
        error: `VPS responded with status ${res.status}`,
      };
    }
  } catch (err: any) {
    // Non-fatal: Log warning and continue (VPS may be temporarily down or undergoing maintenance)
    console.warn(`[VPS Cleanup] Network error contacting VPS storage at ${vpsUrl}:`, err?.message || err);
    return {
      success: false,
      error: err?.message || 'Network error reaching VPS',
    };
  }
}

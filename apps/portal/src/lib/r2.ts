export async function getR2Bucket(context?: any) {
  try {
    const cf = await import('cloudflare:workers').catch(() => null);
    if ((cf as any)?.env?.R2) return (cf as any).env.R2;

    const locals = context?.locals as any;
    const runtimeEnv = locals?.runtime?.env || locals?.cloudflare?.env || locals?.env;
    if (runtimeEnv?.R2) return runtimeEnv.R2;
  } catch (e) {
    // Local Node fallback
  }
  return null;
}

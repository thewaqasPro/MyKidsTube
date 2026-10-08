import { defineMiddleware } from 'astro:middleware';
import { getAuthenticatedParent } from './lib/auth';

export const onRequest = defineMiddleware(async (context, next) => {
  try {
    const auth = await getAuthenticatedParent(context);
    (context.locals as any).user = auth?.user ?? null;
    (context.locals as any).session = auth?.session ?? null;
  } catch (_) {
    (context.locals as any).user = null;
    (context.locals as any).session = null;
  }

  return next();
});

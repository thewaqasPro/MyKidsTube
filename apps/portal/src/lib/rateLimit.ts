const ipAttempts = new Map<string, { count: number; resetAt: number }>();

export function checkRateLimit(
  request: Request,
  maxRequests: number = 10,
  windowMs: number = 60000
): { allowed: boolean; remaining: number } {
  const ip =
    request.headers.get('CF-Connecting-IP') ||
    request.headers.get('x-real-ip') ||
    request.headers.get('x-forwarded-for')?.split(',')[0].trim() ||
    'anonymous_client';

  const now = Date.now();

  // Periodic garbage collection for memory hygiene
  if (ipAttempts.size > 2000) {
    for (const [key, record] of ipAttempts.entries()) {
      if (record.resetAt < now) {
        ipAttempts.delete(key);
      }
    }
  }

  const record = ipAttempts.get(ip);
  if (!record || record.resetAt <= now) {
    ipAttempts.set(ip, { count: 1, resetAt: now + windowMs });
    return { allowed: true, remaining: maxRequests - 1 };
  }

  if (record.count >= maxRequests) {
    return { allowed: false, remaining: 0 };
  }

  record.count += 1;
  return { allowed: true, remaining: maxRequests - record.count };
}

export function createRateLimitResponse(): Response {
  return new Response(
    JSON.stringify({ error: 'Too many requests. Please try again later.' }),
    {
      status: 429,
      headers: {
        'Content-Type': 'application/json',
        'Retry-After': '60',
      },
    }
  );
}

export function getCorsHeaders(
  request: Request,
  options: {
    methods?: string[];
    isStateChanging?: boolean;
  } = {}
): HeadersInit {
  const origin = request.headers.get('Origin');
  const host = request.headers.get('Host');
  const methods = options.methods || ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'];

  const headers: Record<string, string> = {
    'Vary': 'Origin',
    'Access-Control-Allow-Methods': methods.join(', '),
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, Range',
    'Access-Control-Expose-Headers': 'Content-Range, Content-Length, Accept-Ranges',
  };

  // Determine allowed origin
  let isAllowed = false;
  if (origin) {
    const isLocalhost = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
    const isCloudflare = origin.endsWith('.workers.dev') || origin.endsWith('.pages.dev');
    const isWaqasDomain = origin.includes('waqas.pro');
    const isHostMatch = host ? origin.includes(host) : false;

    if (isLocalhost || isCloudflare || isWaqasDomain || isHostMatch) {
      isAllowed = true;
    }
  }

  if (isAllowed && origin) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Access-Control-Allow-Credentials'] = 'true';
  } else if (!options.isStateChanging) {
    // For read-only catalog/profile endpoints accessed from mobile or dev
    headers['Access-Control-Allow-Origin'] = origin || '*';
  }
  // On state-changing endpoints, if origin is unauthorized, no Access-Control-Allow-Origin is set (blocks cross-origin browser fetch)

  return headers;
}

export function handleOptions(request: Request, methods: string[] = ['GET', 'POST', 'OPTIONS']): Response {
  return new Response(null, {
    status: 204,
    headers: getCorsHeaders(request, { methods, isStateChanging: false }),
  });
}

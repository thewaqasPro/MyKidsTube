/**
 * Standardized Edge JSON Response Envelopes
 * Guarantees predictable JSON responses across all Cloudflare Edge API routes.
 */

export interface ApiSuccessResponse<T> {
  success: true;
  data: T;
  meta?: Record<string, unknown>;
}

export interface ApiErrorResponse {
  success: false;
  error: string;
  code?: string;
  details?: unknown;
}

export function jsonSuccess<T>(
  data: T,
  status = 200,
  headers?: HeadersInit,
  meta?: Record<string, unknown>
): Response {
  const payload: ApiSuccessResponse<T> = {
    success: true,
    data,
    ...(meta ? { meta } : {}),
  };

  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  });
}

export function jsonError(
  message: string,
  status = 400,
  code?: string,
  details?: unknown,
  headers?: HeadersInit
): Response {
  const payload: ApiErrorResponse = {
    success: false,
    error: message,
    ...(code ? { code } : {}),
    ...(details ? { details } : {}),
  };

  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  });
}

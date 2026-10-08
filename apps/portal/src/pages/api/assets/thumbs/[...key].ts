import type { APIRoute } from 'astro';
import { getAuthenticatedParent } from '../../../../lib/auth';
import { getDatabase, getVideoById } from '../../../../lib/db';
import { getR2Bucket } from '../../../../lib/r2';
import { API_BASE } from '../../../../lib/constants';

const PLACEHOLDER_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360" viewBox="0 0 640 360" fill="none">
  <rect width="640" height="360" fill="#18181b"/>
  <circle cx="320" cy="180" r="48" fill="#ef4444" fill-opacity="0.15"/>
  <path d="M305 160L345 180L305 200V160Z" fill="#ef4444"/>
  <text x="320" y="250" fill="#71717a" font-family="system-ui, sans-serif" font-size="14" font-weight="600" text-anchor="middle">MyKidsTube Video</text>
</svg>`;

const YOUTUBE_ID_REGEX = /^[a-zA-Z0-9_-]{11}$/;
const ALLOWED_EXTENSIONS = new Set(['', '.webp', '.jpg', '.jpeg', '.png']);
const FETCH_TIMEOUT_MS = 5000;
const MAX_THUMBNAIL_BYTES = 5 * 1024 * 1024; // 5 MB cap

const vpsHostname = (() => {
  try {
    return new URL(API_BASE).hostname;
  } catch {
    return 'kidsapi.waqas.pro';
  }
})();

const ALLOWED_THUMBNAIL_HOSTS = new Set([
  'i.ytimg.com',
  vpsHostname,
]);

function createTimeoutSignal(ms: number): AbortSignal {
  if (typeof AbortSignal !== 'undefined' && typeof AbortSignal.timeout === 'function') {
    return AbortSignal.timeout(ms);
  }
  const controller = new AbortController();
  setTimeout(() => controller.abort(new Error('Fetch timeout')), ms);
  return controller.signal;
}

async function isParentAuthenticated(context: any): Promise<boolean> {
  if (context.locals?.user?.role === 'parent') {
    return true;
  }
  try {
    const auth = await getAuthenticatedParent(context);
    return Boolean(auth && auth.user?.role === 'parent');
  } catch {
    return false;
  }
}

async function isVideoInCatalog(context: any, baseId: string, filename: string): Promise<boolean> {
  const db = await getDatabase(context);
  if (db) {
    try {
      const row = await db
        .prepare('SELECT id FROM videos WHERE id = ? OR youtube_id = ? OR thumbnail_file = ? LIMIT 1')
        .bind(baseId, baseId, filename)
        .first();
      if (row) return true;
    } catch (dbErr) {
      console.error('D1 thumbnail catalog check error:', dbErr);
    }
  }

  // Fallback if D1 direct query is unavailable
  try {
    const video = await getVideoById(baseId, context);
    if (video) return true;
  } catch (err) {
    console.error('Catalog fallback check error:', err);
  }

  return false;
}

export const GET: APIRoute = async (context) => {
  const { key } = context.params;
  if (!key) {
    return new Response(JSON.stringify({ error: 'bad_request', message: 'Key required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const rawKey = Array.isArray(key) ? key.join('/') : String(key);

  let decodedKey = rawKey;
  try {
    decodedKey = decodeURIComponent(rawKey);
  } catch {
    return new Response(JSON.stringify({ error: 'bad_request', message: 'Malformed key parameter' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // 1. Path traversal & invalid path characters check
  if (
    rawKey.includes('..') ||
    decodedKey.includes('..') ||
    rawKey.includes('\\') ||
    decodedKey.includes('\\') ||
    rawKey.includes('\0') ||
    decodedKey.includes('\0')
  ) {
    return new Response(JSON.stringify({ error: 'bad_request', message: 'Path traversal not allowed' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Reject unexpected path nesting: only allow <filename> or thumbs/<filename>
  const segments = decodedKey.split('/').filter(Boolean);
  if (segments.length === 0 || segments.length > 2 || (segments.length === 2 && segments[0] !== 'thumbs')) {
    return new Response(JSON.stringify({ error: 'bad_request', message: 'Invalid key structure' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const filename = segments[segments.length - 1];

  // Filename safe pattern check
  if (!/^[a-zA-Z0-9_.-]+$/.test(filename)) {
    return new Response(JSON.stringify({ error: 'bad_request', message: 'Invalid characters in filename' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Validate file extension
  const extMatch = filename.match(/\.[^.]+$/);
  const ext = extMatch ? extMatch[0].toLowerCase() : '';
  if (!ALLOWED_EXTENSIONS.has(ext)) {
    return new Response(JSON.stringify({ error: 'bad_request', message: 'Unsupported file extension' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Extract baseId: strip extension and optional 'short_' prefix
  const baseId = filename.replace(/\.[^.]+$/, '').replace(/^short_/, '');

  // Validate baseId strictly: must be 11-char [a-zA-Z0-9_-] YouTube ID
  if (!YOUTUBE_ID_REGEX.test(baseId)) {
    return new Response(
      JSON.stringify({ error: 'bad_request', message: 'Invalid baseId format (must be 11 characters)' }),
      {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }

  const r2Key = `thumbs/${filename}`;
  const r2 = await getR2Bucket(context);

  // 2. Check R2 storage first
  if (r2) {
    try {
      const object = await r2.get(r2Key);
      if (object) {
        return new Response(object.body, {
          status: 200,
          headers: {
            'Content-Type': object.httpMetadata?.contentType || 'image/jpeg',
            'Cache-Control': 'public, max-age=31536000, immutable',
            'ETag': object.httpEtag || `"${filename}"`,
            'X-Storage-Source': 'cloudflare-r2',
          },
        });
      }
    } catch (e) {
      console.error('R2 get error:', e);
    }
  }

  // 3. Not in R2: Require parent auth OR restrict to catalog videos in D1
  const isParent = await isParentAuthenticated(context);
  let isAllowed = isParent;

  if (!isAllowed) {
    isAllowed = await isVideoInCatalog(context, baseId, filename);
  }

  if (!isAllowed) {
    return new Response(
      JSON.stringify({
        error: 'unauthorized',
        message: 'Thumbnail fetch requires parent authentication or an existing catalog video',
      }),
      {
        status: 401,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-store',
        },
      }
    );
  }

  // 4. Fetch from YouTube or VPS with strict host allowlist, timeout, and max bytes cap
  const candidateUrls = [
    `https://i.ytimg.com/vi/${baseId}/hqdefault.jpg`,
    `https://i.ytimg.com/vi/${baseId}/maxresdefault.jpg`,
    `https://kidsapi.waqas.pro/media/thumbs/${filename}`,
  ];

  for (const candidateUrl of candidateUrls) {
    try {
      const parsed = new URL(candidateUrl);
      if (parsed.protocol !== 'https:' || !ALLOWED_THUMBNAIL_HOSTS.has(parsed.hostname.toLowerCase())) {
        continue;
      }

      const res = await fetch(candidateUrl, {
        signal: createTimeoutSignal(FETCH_TIMEOUT_MS),
        headers: {
          'User-Agent': 'MyKidsTube/1.0',
          'Accept': 'image/webp,image/jpeg,image/*,*/*',
        },
      });

      if (res.ok) {
        const contentType = res.headers.get('content-type') || 'image/jpeg';
        if (!contentType.toLowerCase().startsWith('image/')) {
          continue;
        }

        const contentLengthHeader = res.headers.get('content-length');
        if (contentLengthHeader) {
          const cl = parseInt(contentLengthHeader, 10);
          if (!isNaN(cl) && cl > MAX_THUMBNAIL_BYTES) {
            continue;
          }
        }

        const buffer = await res.arrayBuffer();
        if (buffer.byteLength > MAX_THUMBNAIL_BYTES || buffer.byteLength === 0) {
          continue;
        }

        // Cache into R2
        if (r2) {
          try {
            await r2.put(r2Key, buffer, {
              httpMetadata: { contentType },
            });
          } catch (putErr) {
            console.error('R2 put error:', putErr);
          }
        }

        return new Response(buffer, {
          status: 200,
          headers: {
            'Content-Type': contentType,
            'Cache-Control': 'public, max-age=31536000, immutable',
            'X-Storage-Source': 'origin-cached-to-r2',
          },
        });
      }
    } catch (_) {
      // Continue to next candidate
    }
  }

  // 5. Fallback placeholder SVG
  return new Response(PLACEHOLDER_SVG, {
    status: 200,
    headers: {
      'Content-Type': 'image/svg+xml',
      'Cache-Control': 'public, max-age=86400',
    },
  });
};

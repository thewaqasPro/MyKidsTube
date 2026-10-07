import type { APIRoute } from 'astro';
import { getR2Bucket } from '../../../../lib/r2';

const PLACEHOLDER_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360" viewBox="0 0 640 360" fill="none">
  <rect width="640" height="360" fill="#18181b"/>
  <circle cx="320" cy="180" r="48" fill="#ef4444" fill-opacity="0.15"/>
  <path d="M305 160L345 180L305 200V160Z" fill="#ef4444"/>
  <text x="320" y="250" fill="#71717a" font-family="system-ui, sans-serif" font-size="14" font-weight="600" text-anchor="middle">MyKidsTube Video</text>
</svg>`;

export const GET: APIRoute = async (context) => {
  const { key } = context.params;
  if (!key) {
    return new Response('Key required', { status: 400 });
  }

  const cleanKey = Array.isArray(key) ? key.join('/') : key;
  const filename = cleanKey.split('/').pop() || cleanKey;
  const r2Key = `thumbs/${filename}`;

  const r2 = await getR2Bucket(context);

  // 1. Check R2 storage first
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

  // 2. Not in R2: Fetch from YouTube or VPS
  const baseId = filename.replace(/\.[^.]+$/, '').replace(/^short_/, '');
  const candidateUrls = [
    `https://i.ytimg.com/vi/${baseId}/hqdefault.jpg`,
    `https://i.ytimg.com/vi/${baseId}/maxresdefault.jpg`,
    `https://kidsapi.waqas.pro/media/thumbs/${filename}`,
  ];

  for (const candidateUrl of candidateUrls) {
    try {
      const res = await fetch(candidateUrl);
      if (res.ok) {
        const contentType = res.headers.get('content-type') || 'image/jpeg';
        const buffer = await res.arrayBuffer();

        // 3. Cache asynchronously into R2
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

  // 4. Fallback placeholder SVG
  return new Response(PLACEHOLDER_SVG, {
    status: 200,
    headers: {
      'Content-Type': 'image/svg+xml',
      'Cache-Control': 'public, max-age=86400',
    },
  });
};

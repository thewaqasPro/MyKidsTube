import type { APIRoute } from 'astro';
import { getDatabase, extractYoutubeId, isValidYoutubeHost, fetchYoutubeOembed, upsertVideo } from '../../../lib/db';
import { getR2Bucket } from '../../../lib/r2';
import { requireParent } from '../../../lib/parentAuth';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['POST', 'OPTIONS']);
};

export const POST: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, { methods: ['POST', 'OPTIONS'], isStateChanging: true });

  try {
    const body = await context.request.json().catch(() => ({}));
    const categoryId = body.category_id || 'cartoons';
    const profileIds: string[] = body.allowed_profile_ids || ['kids_all'];
    const db = await getDatabase(context);
    const addedVideos: any[] = [];

    // Mode A: Direct pre-parsed items (e.g. from playlist inspection preview)
    if (Array.isArray(body.items) && body.items.length > 0) {
      const items = body.items.slice(0, 60);

      for (const item of items) {
        const vidId = String(item.id || '').trim();
        if (!/^[a-zA-Z0-9_-]{11}$/.test(vidId)) continue;

        const title = item.title || `Video ${vidId}`;
        const channelName = item.channel_name || 'YouTube Kids';
        const thumbUrl = item.thumbnail_url || `https://i.ytimg.com/vi/${vidId}/hqdefault.jpg`;
        const sourceUrl = item.youtube_url || item.url || `https://www.youtube.com/watch?v=${vidId}`;
        const isShortUrl = sourceUrl.includes('/shorts/');
        const targetCategory = (!isShortUrl && categoryId === 'shorts') ? 'cartoons' : categoryId;

        if (db) {
          await upsertVideo(db, {
            id: vidId,
            title,
            duration: 0,
            durationFormatted: '--:--',
            categoryId: targetCategory,
            sourceUrl,
            channelName,
            channelIcon: thumbUrl,
            thumbnailUrl: thumbUrl,
            quality: '720p',
            status: 'pending_download',
            allowedProfileIds: profileIds,
          });
        }

        addedVideos.push({
          id: vidId,
          youtube_id: vidId,
          title,
          channel_name: channelName,
          thumbnail_url: thumbUrl,
          status: 'pending_download',
        });
      }

      // Warm thumbnails in R2 for first batch asynchronously
      try {
        const r2 = await getR2Bucket(context);
        if (r2) {
          Promise.all(
            addedVideos.slice(0, 10).map(async (v) => {
              const r2Key = `thumbs/${v.id}.webp`;
              const exists = await r2.get(r2Key).catch(() => null);
              if (!exists) {
                const ytThumb = await fetch(`https://i.ytimg.com/vi/${v.id}/hqdefault.jpg`, {
                  signal: AbortSignal.timeout(4000),
                }).catch(() => null);
                if (ytThumb && ytThumb.ok) {
                  const buf = await ytThumb.arrayBuffer();
                  await r2.put(r2Key, buf, { httpMetadata: { contentType: 'image/jpeg' } }).catch(() => null);
                }
              }
            })
          ).catch(() => {});
        }
      } catch (_) {}

      return new Response(
        JSON.stringify({
          success: true,
          count: addedVideos.length,
          videos: addedVideos,
          message: `${addedVideos.length} video(s) added to kids catalog!`,
        }),
        {
          status: 200,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    // Mode B: List of raw URLs
    const urls: string[] = Array.isArray(body.urls) 
      ? body.urls 
      : (body.url ? [body.url] : []);

    if (urls.length === 0) {
      return new Response(JSON.stringify({ error: 'No URLs or items provided' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // Cap batch size at max 60 URLs per request
    if (urls.length > 60) {
      return new Response(
        JSON.stringify({ error: 'Batch size exceeds maximum limit of 60 URLs per request' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    // Validate every URL host
    for (const rawUrl of urls) {
      const trimmed = String(rawUrl).trim();
      if (!isValidYoutubeHost(trimmed)) {
        return new Response(
          JSON.stringify({ error: `Invalid URL: Only youtube.com, youtu.be, and m.youtube.com URLs are permitted. Received: ${trimmed}` }),
          {
            status: 400,
            headers: { 'Content-Type': 'application/json', ...corsHeaders },
          }
        );
      }
    }

    const validItems: { url: string; ytId: string; isShort: boolean }[] = [];

    for (const rawUrl of urls) {
      const trimmed = String(rawUrl).trim();
      const ytId = extractYoutubeId(trimmed);
      if (!ytId) {
        return new Response(
          JSON.stringify({ error: `Could not parse valid 11-character YouTube video ID from: ${trimmed}` }),
          {
            status: 400,
            headers: { 'Content-Type': 'application/json', ...corsHeaders },
          }
        );
      }
      validItems.push({
        url: trimmed,
        ytId,
        isShort: trimmed.includes('/shorts/'),
      });
    }

    // Fetch oEmbed metadata concurrently in chunks of 5 with timeout
    const metaList: any[] = [];
    for (let i = 0; i < validItems.length; i += 5) {
      const chunk = validItems.slice(i, i + 5);
      const chunkResults = await Promise.all(
        chunk.map((item) => fetchYoutubeOembed(item.ytId, 5000))
      );
      metaList.push(...chunkResults);
    }

    for (let i = 0; i < validItems.length; i++) {
      const item = validItems[i];
      const catId = item.isShort ? 'shorts' : (categoryId === 'shorts' ? 'cartoons' : categoryId);

      if (db) {
        await upsertVideo(db, {
          id: item.ytId,
          title: meta.title,
          duration: 0,
          durationFormatted: '--:--',
          categoryId: catId,
          sourceUrl: item.url,
          channelName: meta.channel_name,
          channelIcon: meta.thumbnail_url,
          thumbnailUrl: meta.thumbnail_url,
          quality: '720p',
          status: 'pending_download',
          allowedProfileIds: profileIds,
        });
      }

      addedVideos.push({
        id: item.ytId,
        youtube_id: item.ytId,
        title: meta.title,
        channel_name: meta.channel_name,
        thumbnail_url: meta.thumbnail_url,
        status: 'pending_download',
      });
    }

    // Warm thumbnails in R2 for first batch asynchronously
    try {
      const r2 = await getR2Bucket(context);
      if (r2) {
        Promise.all(
          addedVideos.slice(0, 10).map(async (v) => {
            const r2Key = `thumbs/${v.id}.webp`;
            const exists = await r2.get(r2Key).catch(() => null);
            if (!exists) {
              const ytThumb = await fetch(`https://i.ytimg.com/vi/${v.id}/hqdefault.jpg`, {
                signal: AbortSignal.timeout(4000),
              }).catch(() => null);
              if (ytThumb && ytThumb.ok) {
                const buf = await ytThumb.arrayBuffer();
                await r2.put(r2Key, buf, { httpMetadata: { contentType: 'image/jpeg' } }).catch(() => null);
              }
            }
          })
        ).catch(() => {});
      }
    } catch (_) {}

    return new Response(
      JSON.stringify({
        success: true,
        count: addedVideos.length,
        videos: addedVideos,
        message: `${addedVideos.length} video(s) added to kids catalog!`,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  } catch (error: any) {
    console.error('Queue add error:', error);
    return new Response(JSON.stringify({ error: 'internal_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

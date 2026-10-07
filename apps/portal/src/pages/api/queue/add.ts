import type { APIRoute } from 'astro';
import { getDatabase, extractYoutubeId, isValidYoutubeHost, fetchYoutubeOembed, upsertVideo } from '../../../lib/db';
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
    const urls: string[] = Array.isArray(body.urls) 
      ? body.urls 
      : (body.url ? [body.url] : []);
    const categoryId = body.category_id || 'cartoons';
    const profileIds: string[] = body.allowed_profile_ids || ['kids_all'];

    if (urls.length === 0) {
      return new Response(JSON.stringify({ error: 'No URLs provided' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // Cap batch size at max 20 URLs per request
    if (urls.length > 20) {
      return new Response(
        JSON.stringify({ error: 'Batch size exceeds maximum limit of 20 URLs per request' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    // Strictly validate every URL host
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

    const db = await getDatabase(context);
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

    // Fetch oEmbed metadata concurrently with timeout
    const metaList = await Promise.all(
      validItems.map((item) => fetchYoutubeOembed(item.ytId, 5000))
    );

    const addedVideos = [];

    for (let i = 0; i < validItems.length; i++) {
      const item = validItems[i];
      const meta = metaList[i];
      const catId = item.isShort ? 'shorts' : categoryId;

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

    return new Response(
      JSON.stringify({
        success: true,
        count: addedVideos.length,
        videos: addedVideos,
        message: `${addedVideos.length} video(s) added to wishlist!`,
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

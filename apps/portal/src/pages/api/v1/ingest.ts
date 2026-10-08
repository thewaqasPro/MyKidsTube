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
    const { url, category_id = 'cartoons', quality = '720p', allowed_profile_ids = ['kids_all'] } = body;

    if (!url || typeof url !== 'string') {
      return new Response(JSON.stringify({ error: 'URL is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const trimmedUrl = url.trim();

    // Strictly validate host
    if (!isValidYoutubeHost(trimmedUrl)) {
      return new Response(
        JSON.stringify({ error: 'Invalid URL: Only youtube.com, youtu.be, and m.youtube.com URLs are permitted' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    const youtubeId = extractYoutubeId(trimmedUrl);
    if (!youtubeId) {
      return new Response(
        JSON.stringify({ error: 'Could not extract valid 11-character YouTube video ID from URL' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    const isShort = trimmedUrl.includes('/shorts/');
    const finalCategory = isShort ? 'shorts' : (category_id === 'shorts' ? 'cartoons' : category_id);

    // 1. Fetch metadata via oEmbed with timeout
    const meta = await fetchYoutubeOembed(youtubeId, 5000);

    // 2. Pre-cache thumbnail to R2 if available
    const r2 = await getR2Bucket(context);
    if (r2 && meta.thumbnail_url) {
      try {
        const thumbRes = await fetch(meta.thumbnail_url, { signal: AbortSignal.timeout(5000) });
        if (thumbRes.ok) {
          const thumbBuffer = await thumbRes.arrayBuffer();
          await r2.put(`thumbs/${youtubeId}.webp`, thumbBuffer, {
            httpMetadata: { contentType: 'image/jpeg' },
          });
        }
      } catch (r2Err) {
        console.error('Failed to pre-cache thumb to R2:', r2Err);
      }
    }

    // 3. Insert or update in D1 using unified helper
    const db = await getDatabase(context);
    if (db) {
      await upsertVideo(db, {
        id: youtubeId,
        title: meta.title,
        duration: 0,
        durationFormatted: '--:--',
        categoryId: finalCategory,
        sourceUrl: trimmedUrl,
        channelName: meta.channel_name,
        channelIcon: meta.thumbnail_url,
        thumbnailUrl: meta.thumbnail_url,
        quality,
        status: 'pending_download',
        allowedProfileIds: allowed_profile_ids,
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Video added to catalog and queued for offline sync!',
        video: {
          id: youtubeId,
          title: meta.title,
          category_id: finalCategory,
          status: 'pending_download',
          stream_url: `https://kidsapi.waqas.pro/media/videos/${youtubeId}.mp4`,
          thumbnail_url: `https://mykidstube.kidstube.workers.dev/api/assets/thumbs/${youtubeId}.webp`,
          channel_name: meta.channel_name,
        },
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  } catch (error: any) {
    console.error('v1/ingest error:', error);
    return new Response(
      JSON.stringify({ error: 'internal_error' }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
};

import type { APIRoute } from 'astro';
import { getDbData } from '../../../lib/db';
import { getYoutubeId } from '../../../lib/constants';
import { getCorsHeaders, handleOptions } from '../../../lib/cors';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['GET', 'OPTIONS']);
};

export const GET: APIRoute = async (context) => {
  const corsHeaders = getCorsHeaders(context.request, { methods: ['GET', 'OPTIONS'], isStateChanging: false });

  try {
    const url = new URL(context.request.url);
    const profileId = url.searchParams.get('profile_id') || undefined;
    const data = await getDbData(context, profileId);
    const { videos = [], categories = [], profiles = [] } = data;

    const formattedVideos = videos.map((v: any) => {
      const vidFile = v.video_file || `${v.id}.mp4`;
      const thumbFile = v.thumbnail_file || `${v.id}.webp`;
      const ytId = getYoutubeId({ id: v.id, youtube_id: v.youtube_id });

      return {
        id: v.id,
        profile_id: v.profile_id || (profileId || 'kids_all'),
        title: v.title,
        duration: v.duration || 0,
        duration_formatted: v.duration_formatted || '00:00',
        category_id: v.category_id || 'cartoons',
        source_url: v.source_url || (v.category_id === 'shorts' && (!v.duration || v.duration <= 70) ? `https://www.youtube.com/shorts/${ytId}` : `https://www.youtube.com/watch?v=${ytId}`),
        stream_url: `https://kidsapi.waqas.pro/media/videos/${vidFile}`,
        thumbnail_url: `https://mykidstube.kidstube.workers.dev/api/assets/thumbs/${thumbFile}`,
        channel_name: v.channel_name || 'YouTube Kids',
        channel_icon_url: v.channel_icon || '',
        file_size_bytes: v.file_size_bytes || 0,
        quality: v.quality || '720p',
        status: v.status || (v.file_verified ? 'ready' : 'pending_download'),
        views: v.views || 0,
        watch_seconds: v.watch_seconds || 0,
        youtube_id: ytId,
      };
    });

    // Group into sections by category for mobile client
    const sections = categories.map((cat: any) => ({
      category: {
        id: cat.id,
        name: cat.name,
        icon: cat.icon || 'tv',
        display_order: cat.display_order ?? 0,
      },
      videos: formattedVideos.filter((v: any) => v.category_id === cat.id),
    }));

    return new Response(
      JSON.stringify({
        sections,
        all_videos: formattedVideos,
        categories,
        profiles,
        source: data.source,
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'private, max-age=60',
          ...corsHeaders,
        },
      }
    );
  } catch (error: any) {
    console.error('v1/catalog error:', error);
    return new Response(
      JSON.stringify({ error: 'internal_error' }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    );
  }
};

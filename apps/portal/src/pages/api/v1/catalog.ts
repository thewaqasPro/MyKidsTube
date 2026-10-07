import type { APIRoute } from 'astro';
import { getDbData } from '../../../lib/db';

export const GET: APIRoute = async (context) => {
  try {
    const data = await getDbData(context);
    const { videos = [], categories = [], profiles = [] } = data;

    const formattedVideos = videos.map((v: any) => {
      const vidFile = v.video_file || `${v.id}.mp4`;
      const thumbFile = v.thumbnail_file || `${v.id}.webp`;

      return {
        id: v.id,
        title: v.title,
        duration: v.duration || 0,
        duration_formatted: v.duration_formatted || '00:00',
        category_id: v.category_id || 'cartoons',
        source_url: v.source_url || `https://www.youtube.com/watch?v=${v.id}`,
        stream_url: `https://kidsapi.waqas.pro/media/videos/${vidFile}`,
        thumbnail_url: `https://mykidstube.kidstube.workers.dev/api/assets/thumbs/${thumbFile}`,
        channel_name: v.channel_name || 'YouTube Kids',
        channel_icon_url: v.channel_icon || '',
        file_size_bytes: v.file_size_bytes || 0,
        quality: v.quality || '720p',
        status: v.status || (v.file_verified ? 'ready' : 'pending_download'),
        views: v.views || 0,
        watch_seconds: v.watch_seconds || 0,
        youtube_id: v.youtube_id || v.id,
      };
    });

    // Group into sections by category for Flutter AppProvider
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
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300',
        },
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    );
  }
};

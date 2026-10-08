import type { APIRoute } from 'astro';
import { requireParent } from '@/lib/parentAuth';
import { getCorsHeaders, handleOptions } from '@/lib/cors';
import { isValidYoutubeHost } from '@/shared/utils/youtube';
import { extractPlaylistFromUrl } from '@/shared/utils/innertubePlaylist';

export const OPTIONS: APIRoute = async ({ request }) => {
  return handleOptions(request, ['POST', 'OPTIONS']);
};

export const POST: APIRoute = async (context) => {
  const authErr = await requireParent(context);
  if (authErr) return authErr;

  const corsHeaders = getCorsHeaders(context.request, {
    methods: ['POST', 'OPTIONS'],
    isStateChanging: false,
  });

  try {
    const body = (await context.request.json().catch(() => ({}))) as Record<string, unknown>;
    const rawUrl = String(body.playlist_url || body.url || '').trim();

    if (!rawUrl) {
      return new Response(JSON.stringify({ error: 'playlist_url is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    if (!isValidYoutubeHost(rawUrl)) {
      return new Response(
        JSON.stringify({
          error: 'Invalid URL. Only YouTube links (youtube.com, youtu.be, m.youtube.com) are supported.',
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        }
      );
    }

    const result = await extractPlaylistFromUrl(rawUrl);

    return new Response(
      JSON.stringify({
        success: true,
        playlist_id: result.playlistId,
        playlist_title: result.playlistTitle,
        total_discovered: result.videos.length,
        count: result.videos.length,
        videos: result.videos,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  } catch (error: any) {
    console.error('Playlist extract error:', error);
    const status = error?.message?.includes('not discover') ? 404 : 500;
    return new Response(
      JSON.stringify({ error: error?.message || 'Failed to extract playlist' }),
      {
        status,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      }
    );
  }
};

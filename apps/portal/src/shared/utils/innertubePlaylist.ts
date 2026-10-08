import { getYoutubeMetadata } from './youtube';

export interface ExtractedPlaylistItem {
  id: string;
  title: string;
  channel_name: string;
  thumbnail_url: string;
  youtube_url: string;
}

export interface ExtractedPlaylistResult {
  playlistId: string;
  playlistTitle: string;
  videos: ExtractedPlaylistItem[];
}

export async function extractPlaylistFromUrl(rawUrl: string): Promise<ExtractedPlaylistResult> {
  const parsedUrl = new URL(rawUrl);
  const listId = parsedUrl.searchParams.get('list');
  const videoIdParam = parsedUrl.searchParams.get('v');

  if (!listId) {
    throw new Error('URL does not contain a playlist or mix identifier (missing list parameter).');
  }

  let playlistTitle = 'YouTube Playlist';
  const videos: ExtractedPlaylistItem[] = [];

  const innertubeHeaders = {
    'Content-Type': 'application/json',
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  };

  const innertubeContext = {
    client: {
      clientName: 'WEB',
      clientVersion: '2.20240301.00.00',
      hl: 'en',
      gl: 'US',
    },
  };

  // Strategy A: YouTube Innertube /next endpoint (ideal for mix playlists and watch URLs)
  if (videoIdParam || listId.startsWith('RD') || listId.startsWith('UL')) {
    try {
      const nextRes = await fetch('https://www.youtube.com/youtubei/v1/next', {
        method: 'POST',
        headers: innertubeHeaders,
        body: JSON.stringify({
          context: innertubeContext,
          videoId: videoIdParam || undefined,
          playlistId: listId,
        }),
        signal: AbortSignal.timeout(8000),
      });

      if (nextRes.ok) {
        const nextData: any = await nextRes.json();
        const panel = nextData.contents?.twoColumnWatchNextResults?.playlist?.playlist;
        if (panel) {
          playlistTitle = panel.title || playlistTitle;
          const items = panel.contents || [];
          for (const item of items) {
            const renderer = item.playlistPanelVideoRenderer;
            if (renderer && renderer.videoId) {
              const vid = renderer.videoId;
              const title =
                renderer.title?.simpleText || renderer.title?.runs?.[0]?.text || `Video ${vid}`;
              const channel = renderer.shortBylineText?.runs?.[0]?.text || 'YouTube';
              const thumb =
                renderer.thumbnail?.thumbnails?.[renderer.thumbnail.thumbnails.length - 1]?.url ||
                `https://i.ytimg.com/vi/${vid}/hqdefault.jpg`;

              videos.push({
                id: vid,
                title,
                channel_name: channel,
                thumbnail_url: thumb,
                youtube_url: `https://www.youtube.com/watch?v=${vid}`,
              });
            }
          }
        }
      }
    } catch (err) {
      console.warn('Innertube /next lookup error:', err);
    }
  }

  // Strategy B: YouTube Innertube /browse endpoint (ideal for standard playlists PL...)
  if (videos.length === 0) {
    try {
      const browseId = listId.startsWith('VL') ? listId : `VL${listId}`;
      const browseRes = await fetch('https://www.youtube.com/youtubei/v1/browse', {
        method: 'POST',
        headers: innertubeHeaders,
        body: JSON.stringify({
          context: innertubeContext,
          browseId,
        }),
        signal: AbortSignal.timeout(8000),
      });

      if (browseRes.ok) {
        const browseData: any = await browseRes.json();
        const headerTitle =
          browseData.header?.playlistHeaderRenderer?.title?.simpleText ||
          browseData.metadata?.playlistMetadataRenderer?.title;
        if (headerTitle) playlistTitle = headerTitle;

        const jsonStr = JSON.stringify(browseData);
        const idMatches = [...jsonStr.matchAll(/"videoId":"([a-zA-Z0-9_-]{11})"/g)].map((m) => m[1]);
        const uniqueIds = Array.from(new Set(idMatches)).slice(0, 50);

        if (uniqueIds.length > 0) {
          for (let i = 0; i < uniqueIds.length; i += 5) {
            const chunk = uniqueIds.slice(i, i + 5);
            const batch = await Promise.all(
              chunk.map(async (vid) => {
                const meta = await getYoutubeMetadata(vid);
                return {
                  id: vid,
                  title: meta.title || `Video ${vid}`,
                  channel_name: meta.channel_name || 'YouTube',
                  thumbnail_url: meta.thumbnail_url || `https://i.ytimg.com/vi/${vid}/hqdefault.jpg`,
                  youtube_url: `https://www.youtube.com/watch?v=${vid}`,
                };
              })
            );
            videos.push(...batch);
          }
        }
      }
    } catch (err) {
      console.warn('Innertube /browse lookup error:', err);
    }
  }

  // Strategy C: Fallback to RSS feed for standard playlists
  if (videos.length === 0 && listId.startsWith('PL')) {
    try {
      const rssRes = await fetch(`https://www.youtube.com/feeds/videos.xml?playlist_id=${listId}`, {
        signal: AbortSignal.timeout(6000),
      });
      if (rssRes.ok) {
        const xml = await rssRes.text();
        const titleMatch = xml.match(/<title>(.*?)<\/title>/);
        if (titleMatch && titleMatch[1]) playlistTitle = titleMatch[1];

        const idMatches = [...xml.matchAll(/<yt:videoId>(.*?)<\/yt:videoId>/g)].map((m) => m[1]);
        const uniqueIds = Array.from(new Set(idMatches)).slice(0, 50);

        for (const vid of uniqueIds) {
          const meta = await getYoutubeMetadata(vid);
          videos.push({
            id: vid,
            title: meta.title || `Video ${vid}`,
            channel_name: meta.channel_name || 'YouTube',
            thumbnail_url: meta.thumbnail_url || `https://i.ytimg.com/vi/${vid}/hqdefault.jpg`,
            youtube_url: `https://www.youtube.com/watch?v=${vid}`,
          });
        }
      }
    } catch (err) {
      console.warn('RSS fallback error:', err);
    }
  }

  // Deduplicate videos by ID
  const seen = new Set<string>();
  const deduplicatedVideos: ExtractedPlaylistItem[] = [];
  for (const v of videos) {
    if (!seen.has(v.id)) {
      seen.add(v.id);
      deduplicatedVideos.push(v);
    }
  }

  if (deduplicatedVideos.length === 0) {
    throw new Error('Could not discover any video items in this playlist or mix.');
  }

  return {
    playlistId: listId,
    playlistTitle,
    videos: deduplicatedVideos,
  };
}

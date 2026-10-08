/**
 * YouTube URL parsing and oEmbed metadata retrieval utilities
 */

export function isValidYoutubeHost(inputUrl: string): boolean {
  try {
    const url = new URL(inputUrl);
    const host = url.hostname.toLowerCase();
    return ['youtube.com', 'www.youtube.com', 'youtu.be', 'm.youtube.com'].includes(host);
  } catch {
    return false;
  }
}

export function extractYoutubeId(inputUrl: string): string | null {
  const trimmed = inputUrl.trim();
  if (/^[a-zA-Z0-9_-]{11}$/.test(trimmed)) {
    return trimmed;
  }

  try {
    const url = new URL(trimmed);
    const host = url.hostname.toLowerCase();
    if (!['youtube.com', 'www.youtube.com', 'youtu.be', 'm.youtube.com'].includes(host)) {
      return null;
    }

    if (host === 'youtu.be') {
      const seg = url.pathname.slice(1).split('/')[0];
      return /^[a-zA-Z0-9_-]{11}$/.test(seg) ? seg : null;
    }

    if (url.pathname.includes('/shorts/')) {
      const match = url.pathname.match(/\/shorts\/([a-zA-Z0-9_-]{11})/);
      return match ? match[1] : null;
    }

    if (url.pathname.includes('/embed/')) {
      const match = url.pathname.match(/\/embed\/([a-zA-Z0-9_-]{11})/);
      return match ? match[1] : null;
    }

    const vParam = url.searchParams.get('v');
    if (vParam && /^[a-zA-Z0-9_-]{11}$/.test(vParam)) {
      return vParam;
    }

    return null;
  } catch {
    return null;
  }
}

export interface YoutubeOEmbedMetadata {
  id: string;
  title: string;
  channel_name: string;
  channel_url: string;
  thumbnail_url: string;
}

export async function getYoutubeMetadata(youtubeId: string): Promise<YoutubeOEmbedMetadata> {
  try {
    const res = await fetch(`https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${youtubeId}&format=json`, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; KidsTube/1.0; +https://mykidstube.com)',
      },
    });

    if (res.ok) {
      const data = await res.json() as any;
      return {
        id: youtubeId,
        title: data.title || 'Kids Video',
        channel_name: data.author_name || 'YouTube Kids',
        channel_url: data.author_url || '',
        thumbnail_url: data.thumbnail_url || `https://i.ytimg.com/vi/${youtubeId}/hqdefault.jpg`,
      };
    }
  } catch (e) {
    console.error(`oEmbed fetch error for ${youtubeId}:`, e);
  }

  return {
    id: youtubeId,
    title: 'Kids Video',
    channel_name: 'KidsTube',
    channel_url: '',
    thumbnail_url: `https://i.ytimg.com/vi/${youtubeId}/hqdefault.jpg`,
  };
}

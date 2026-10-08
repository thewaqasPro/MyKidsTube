import React, { useState } from 'react';
import type { Video } from '@/types/video';
import { getThumbnailUrl, getChannelIconUrl, isVideoShort } from '@/lib/constants';
import { Play, Heart, ShieldCheck } from 'lucide-react';

interface VideoCardProps {
  video: Video;
  onPlay: (video: Video) => void;
  isFavorite?: boolean;
  onToggleFavorite?: (videoId: string, e: React.MouseEvent) => void;
}

export const VideoCard: React.FC<VideoCardProps> = ({
  video,
  onPlay,
  isFavorite = false,
  onToggleFavorite,
}) => {
  const [imgError, setImgError] = useState(false);
  const [avatarError, setAvatarError] = useState(false);

  const thumbUrl = getThumbnailUrl(video);
  const avatarUrl = getChannelIconUrl(video);

  const cleanChannelName = video.channel_name || (video.title.includes('•') ? video.title.split('•')[0].trim() : 'KidsTube');
  const cleanTitle = video.title.includes('•') ? video.title.split('•').slice(1).join('•').trim() : video.title;

  return (
    <a
      href={isVideoShort(video) ? `/shorts?v=${video.id}` : `/watch/${video.id}`}
      className="group flex flex-col cursor-pointer select-none no-underline transition-all duration-200 card-hover-pop"
    >
      {/* 16:9 Thumbnail Container with WonderKids 20px Rounded Frame */}
      <div className="relative aspect-video w-full overflow-hidden rounded-[20px] bg-surface border border-border shadow-sm group-hover:border-sky/40 transition-colors">
        {!imgError ? (
          <img
            src={thumbUrl}
            alt={video.title}
            loading="lazy"
            onError={() => setImgError(true)}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex flex-col items-center justify-center bg-surface text-text-muted">
            <Play className="w-10 h-10 opacity-40 text-sky" />
            <span className="text-[12px] mt-1 font-display font-medium text-text-secondary">Safe Video</span>
          </div>
        )}

        {/* Favorite Heart Button with Playful Pop */}
        {onToggleFavorite && (
          <button
            onClick={(e) => onToggleFavorite(video.id, e)}
            title={isFavorite ? 'Remove from Favorites' : 'Add to Favorites'}
            className={`absolute top-2.5 right-2.5 p-2 rounded-full bg-canvas-deep/75 backdrop-blur-md transition-all cursor-pointer ${
              isFavorite
                ? 'opacity-100 text-coral scale-110'
                : 'opacity-0 group-hover:opacity-100 text-white/80 hover:text-coral hover:scale-110'
            }`}
          >
            <Heart className={`w-4 h-4 ${isFavorite ? 'fill-current' : ''}`} />
          </button>
        )}

        {/* Playful Floating Play Bubble on Hover */}
        <div className="absolute inset-0 bg-black/20 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center pointer-events-none">
          <div className="w-13 h-13 rounded-full bg-gradient-to-tr from-coral to-sun text-white flex items-center justify-center shadow-lg shadow-coral/40 transform scale-90 group-hover:scale-100 transition-transform">
            <Play className="w-6 h-6 fill-current ml-0.5" />
          </div>
        </div>

        {/* Duration Badge Pill */}
        <div className="absolute bottom-2.5 right-2.5 px-2 py-0.5 rounded-full bg-canvas-deep/85 backdrop-blur-md border border-white/10 text-[11px] font-bold text-white tracking-wide font-mono">
          {video.duration_formatted || '03:00'}
        </div>
      </div>

      {/* Info Section */}
      <div className="flex gap-3 pt-3.5 pb-1">
        {/* Channel Avatar with Cheerful Ring */}
        <div className="shrink-0 mt-0.5">
          {avatarUrl && !avatarError ? (
            <img
              src={avatarUrl}
              alt={cleanChannelName}
              loading="lazy"
              onError={() => setAvatarError(true)}
              className="w-9 h-9 rounded-full object-cover bg-surface ring-2 ring-sky/40 ring-offset-2 ring-offset-canvas"
            />
          ) : (
            <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-coral to-sun flex items-center justify-center text-white text-[13px] font-display font-bold shadow-sm ring-2 ring-coral/30 ring-offset-2 ring-offset-canvas">
              {cleanChannelName.charAt(0).toUpperCase()}
            </div>
          )}
        </div>

        {/* Title & Metadata */}
        <div className="flex flex-col min-w-0 flex-1">
          <h3
            className="text-[14.5px] font-bold leading-snug text-white group-hover:text-sky line-clamp-2 transition-colors"
            title={video.title}
          >
            {cleanTitle || video.title}
          </h3>

          <div className="mt-1 flex flex-col text-[12px] text-text-secondary">
            <span className="truncate hover:text-white transition-colors font-medium">
              {cleanChannelName}
            </span>
            <div className="flex items-center gap-1.5 text-[11px] text-text-muted mt-0.5 font-medium">
              <span className="inline-flex items-center gap-1 text-mint font-semibold">
                <ShieldCheck className="w-3 h-3 text-mint" />
                Kid Safe
              </span>
              <span>•</span>
              <span>HD</span>
            </div>
          </div>
        </div>
      </div>
    </a>
  );
};

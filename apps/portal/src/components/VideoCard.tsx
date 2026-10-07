import React, { useState } from 'react';
import type { Video } from '../types/video';
import { getThumbnailUrl, getChannelIconUrl, isVideoShort } from '../lib/constants';
import { Play, Heart } from 'lucide-react';

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
      className="group flex flex-col cursor-pointer select-none transition-transform duration-150 active:scale-[0.99] text-inherit no-underline"
    >
      {/* 16:9 Thumbnail Container */}
      <div className="relative aspect-video w-full overflow-hidden rounded-xl bg-[#202020] border border-[#222222]">
        {!imgError ? (
          <img
            src={thumbUrl}
            alt={video.title}
            loading="lazy"
            onError={() => setImgError(true)}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex flex-col items-center justify-center bg-[#1c1c1c] text-[#717171]">
            <Play className="w-10 h-10 opacity-30 text-white" />
            <span className="text-[11px] mt-1 font-medium">Safe Video</span>
          </div>
        )}

        {/* Favorite Heart Button (Top Right) */}
        {onToggleFavorite && (
          <button
            onClick={(e) => onToggleFavorite(video.id, e)}
            title={isFavorite ? 'Remove from Favorites' : 'Add to Favorites'}
            className={`absolute top-2 right-2 p-1.5 rounded-full bg-black/60 backdrop-blur-md transition-all ${
              isFavorite
                ? 'opacity-100 text-[#FF0000]'
                : 'opacity-0 group-hover:opacity-100 text-white hover:text-[#FF4E45] hover:bg-black/80'
            }`}
          >
            <Heart className={`w-3.5 h-3.5 ${isFavorite ? 'fill-current' : ''}`} />
          </button>
        )}

        {/* Hover Overlay Play Icon */}
        <div className="absolute inset-0 bg-black/25 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center pointer-events-none">
          <div className="w-12 h-12 rounded-full bg-[#FF0000]/90 text-white flex items-center justify-center shadow-lg transform scale-90 group-hover:scale-100 transition-transform">
            <Play className="w-5 h-5 fill-current ml-0.5" />
          </div>
        </div>

        {/* Duration Badge */}
        <div className="absolute bottom-2 right-2 px-1.5 py-0.5 rounded bg-black/80 text-[11px] font-bold text-white tracking-wide">
          {video.duration_formatted || '03:00'}
        </div>
      </div>

      {/* Info Section */}
      <div className="flex gap-3 pt-3 pb-1">
        {/* Channel Avatar (36x36px) */}
        <div className="shrink-0">
          {avatarUrl && !avatarError ? (
            <img
              src={avatarUrl}
              alt={cleanChannelName}
              loading="lazy"
              onError={() => setAvatarError(true)}
              className="w-9 h-9 rounded-full object-cover bg-[#2a2a2a] border border-[#333333]"
            />
          ) : (
            <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-rose-600 to-amber-500 flex items-center justify-center text-white text-[13px] font-bold">
              {cleanChannelName.charAt(0).toUpperCase()}
            </div>
          )}
        </div>

        {/* Title & Metadata */}
        <div className="flex flex-col min-w-0 flex-1">
          <h3
            className="text-[14px] font-medium leading-snug text-[#F1F1F1] group-hover:text-white line-clamp-2"
            title={video.title}
          >
            {cleanTitle || video.title}
          </h3>

          <div className="mt-1 flex flex-col text-[12px] text-[#AAAAAA]">
            <span className="truncate hover:text-[#F1F1F1] transition-colors">
              {cleanChannelName}
            </span>
            <div className="flex items-center gap-1.5 text-[11px] text-[#888888] mt-0.5">
              <span>Verified Safe</span>
              <span>•</span>
              <span>HD 720p</span>
            </div>
          </div>
        </div>
      </div>
    </a>
  );
};

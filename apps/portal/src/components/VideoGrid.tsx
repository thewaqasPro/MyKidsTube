import React from 'react';
import type { Video } from '../types/video';
import { VideoCard } from './VideoCard';
import { Film } from 'lucide-react';

interface VideoGridProps {
  videos: Video[];
  onPlayVideo: (video: Video) => void;
  title?: string;
  favorites?: Set<string>;
  onToggleFavorite?: (videoId: string, e: React.MouseEvent) => void;
  emptyMessage?: string;
}

export const VideoGrid: React.FC<VideoGridProps> = ({
  videos,
  onPlayVideo,
  title,
  favorites,
  onToggleFavorite,
  emptyMessage,
}) => {
  if (videos.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-20 px-4 text-center">
        <div className="w-16 h-16 rounded-full bg-[#222222] flex items-center justify-center text-[#777777] mb-3">
          <Film className="w-8 h-8" />
        </div>
        <h3 className="text-[17px] font-semibold text-white">No videos found</h3>
        <p className="text-[13px] text-[#AAAAAA] mt-1 max-w-sm">
          {emptyMessage || 'Try selecting another category or clearing your search query.'}
        </p>
      </div>
    );
  }

  return (
    <div className="px-4 sm:px-6 my-6">
      {title && (
        <h2 className="text-[19px] font-bold text-white tracking-tight mb-4">{title}</h2>
      )}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-x-4 gap-y-7 sm:gap-y-8">
        {videos.map((video) => (
          <VideoCard
            key={video.id}
            video={video}
            onPlay={onPlayVideo}
            isFavorite={favorites?.has(video.id)}
            onToggleFavorite={onToggleFavorite}
          />
        ))}
      </div>
    </div>
  );
};

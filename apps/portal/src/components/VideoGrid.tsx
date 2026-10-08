import React from 'react';
import type { Video } from '../types/video';
import { VideoCard } from './VideoCard';
import { Sparkles, Compass } from 'lucide-react';

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
      <div className="flex flex-col items-center justify-center py-24 px-4 text-center">
        <div className="w-20 h-20 rounded-3xl bg-gradient-to-tr from-[#38BDF8]/20 to-[#A855F7]/20 border-2 border-[#38BDF8]/30 flex items-center justify-center text-[#38BDF8] mb-4 shadow-lg shadow-[#38BDF8]/10 animate-bounce">
          <Compass className="w-10 h-10" />
        </div>
        <h3 className="text-xl font-display font-black text-white tracking-wide">Ready for an Adventure?</h3>
        <p className="text-sm text-[#94A3B8] mt-2 max-w-sm font-medium">
          {emptyMessage || 'No videos found in this corner yet! Try choosing a different topic or clearing your search.'}
        </p>
      </div>
    );
  }

  return (
    <div className="px-4 sm:px-6 my-8">
      {title && (
        <div className="flex items-center gap-2.5 mb-5">
          <span className="w-2.5 h-2.5 rounded-full bg-[#FF5E62] shadow-sm shadow-[#FF5E62]" />
          <h2 className="text-xl sm:text-2xl font-display font-black text-white tracking-wide">{title}</h2>
          <Sparkles className="w-4 h-4 text-[#FFB300]" />
        </div>
      )}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-x-5 gap-y-8 sm:gap-y-9">
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


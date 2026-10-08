import React from 'react';
import type { Video } from '@/types/video';
import { Heart, Zap, Tv, ShieldCheck, Info } from 'lucide-react';

interface WatchDetailsProps {
  video: Video;
  cleanTitle: string;
  cleanChannelName: string;
  avatarUrl: string;
  isFavorite: boolean;
  toggleFavorite: () => void;
  selfHostedAvailable: boolean;
  setForceEmbed: React.Dispatch<React.SetStateAction<boolean>>;
}

export const WatchDetails: React.FC<WatchDetailsProps> = ({
  video,
  cleanTitle,
  cleanChannelName,
  avatarUrl,
  isFavorite,
  toggleFavorite,
  selfHostedAvailable,
  setForceEmbed,
}) => {
  return (
    <div className="mt-5 pb-6 border-b border-border">
      <h1 className="text-xl sm:text-2xl lg:text-3xl font-display line-clamp-1 font-black leading-snug text-white tracking-wide">
        {cleanTitle}
      </h1>

      <div className="mt-4 flex flex-wrap items-center justify-between gap-4">
        {/* Channel Avatar & Info */}
        <div className="flex items-center gap-3.5">
          {avatarUrl ? (
            <img
              src={avatarUrl}
              alt={cleanChannelName}
              className="w-11 h-11 rounded-2xl object-cover bg-surface ring-2 ring-sky shadow-md shadow-sky/20"
            />
          ) : (
            <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-coral to-sun flex items-center justify-center text-white font-black text-base shadow-md shadow-coral/20">
              {cleanChannelName.charAt(0).toUpperCase()}
            </div>
          )}

          <div className="flex flex-col">
            <span className="font-display font-black text-white text-base leading-tight">
              {cleanChannelName}
            </span>
            <div className="flex items-center gap-2 mt-0.5">
              <span className="text-xs px-2 py-0.5 rounded-full bg-sky/15 text-sky border border-sky/30 font-bold capitalize">
                {video.category_id}
              </span>
              <span className="text-xs text-mint font-bold flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-mint" />
                Safe Content
              </span>
            </div>
          </div>
        </div>

        {/* Actions & Badges */}
        <div className="flex items-center gap-3">
          {/* Favorite Button */}
          <button
            onClick={toggleFavorite}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-2xl text-xs font-black transition-all cursor-pointer shadow-md active:scale-95 ${
              isFavorite
                ? 'bg-gradient-to-r from-coral to-coral-hover text-white shadow-coral/30 border-2 border-coral'
                : 'bg-surface hover:bg-surface-hover text-white border-2 border-border'
            }`}
          >
            <Heart className={`w-4 h-4 ${isFavorite ? 'fill-current' : ''}`} />
            <span>{isFavorite ? 'Favorited ❤️' : 'Add to Favorites'}</span>
          </button>

          {/* Mode Switcher */}
          <button
            onClick={() => setForceEmbed((prev) => !prev)}
            className="px-4 py-2.5 bg-surface hover:bg-surface-hover text-text-secondary hover:text-white rounded-2xl text-xs font-bold border-2 border-border transition-colors cursor-pointer"
            title="Toggle between direct stream and embed player"
          >
            {selfHostedAvailable ? 'Switch to Embed' : 'Direct Play'}
          </button>

          {/* Stream Status Badge */}
          <span className="px-3.5 py-2 rounded-2xl bg-surface border-2 border-border text-xs font-bold text-text-secondary hidden sm:inline-flex items-center gap-1.5">
            {selfHostedAvailable ? (
              <>
                <Zap className="w-3.5 h-3.5 text-sun" />
                <span>Fast Stream</span>
              </>
            ) : (
              <>
                <Tv className="w-3.5 h-3.5 text-sky" />
                <span>Smart Stream</span>
              </>
            )}
          </span>
        </div>
      </div>

      {/* Video Description Box & Privacy Transparency */}
      <div className="hidden mt-5 p-5 rounded-3xl bg-surface border-2 border-border text-sm text-text-secondary leading-relaxed shadow-lg">
        <div className="flex items-center gap-3 font-bold text-white mb-2">
          <span>{video.views || 0} plays</span>
          <span>•</span>
          <span>Category: <span className="text-sky capitalize">{video.category_id}</span></span>
        </div>
        <p className="font-medium">
          Curated safe content verified for young learners and happy playtime.
        </p>
        <div className="mt-3 pt-3 border-t border-border text-xs">
          {selfHostedAvailable ? (
            <span className="text-mint font-bold inline-flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-mint shrink-0" />
              <span>Private Stream: Playing from your verified private storage. Zero external ad telemetry.</span>
            </span>
          ) : (
            <span className="inline-flex items-start gap-2 text-text-secondary">
              <Info className="w-4 h-4 text-sky shrink-0 mt-0.5" />
              <span><strong>Kid-Safe Shield Active:</strong> External recommendations and distractions are automatically blocked for worry-free watching.</span>
            </span>
          )}
        </div>
      </div>
    </div>
  );
};

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
    <div className="mt-5 pb-6 border-b border-[#1E294B]">
      <h1 className="text-xl sm:text-2xl lg:text-3xl font-display font-black leading-snug text-white tracking-wide">
        {cleanTitle}
      </h1>

      <div className="mt-4 flex flex-wrap items-center justify-between gap-4">
        {/* Channel Avatar & Info */}
        <div className="flex items-center gap-3.5">
          {avatarUrl ? (
            <img
              src={avatarUrl}
              alt={cleanChannelName}
              className="w-11 h-11 rounded-2xl object-cover bg-[#151D33] ring-2 ring-[#38BDF8] shadow-md shadow-[#38BDF8]/20"
            />
          ) : (
            <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-[#FF5E62] to-[#FFB300] flex items-center justify-center text-white font-black text-base shadow-md shadow-[#FF5E62]/20">
              {cleanChannelName.charAt(0).toUpperCase()}
            </div>
          )}

          <div className="flex flex-col">
            <span className="font-display font-black text-white text-base leading-tight">
              {cleanChannelName}
            </span>
            <div className="flex items-center gap-2 mt-0.5">
              <span className="text-xs px-2 py-0.5 rounded-full bg-[#38BDF8]/15 text-[#38BDF8] border border-[#38BDF8]/30 font-bold capitalize">
                {video.category_id}
              </span>
              <span className="text-xs text-[#10B981] font-bold flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-[#10B981]" />
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
                ? 'bg-gradient-to-r from-[#FF5E62] to-[#FF8E53] text-white shadow-[#FF5E62]/30 border-2 border-[#FF5E62]'
                : 'bg-[#151D33] hover:bg-[#1E294B] text-white border-2 border-[#1E294B]'
            }`}
          >
            <Heart className={`w-4 h-4 ${isFavorite ? 'fill-current' : ''}`} />
            <span>{isFavorite ? 'Favorited ❤️' : 'Add to Favorites'}</span>
          </button>

          {/* Mode Switcher */}
          <button
            onClick={() => setForceEmbed((prev) => !prev)}
            className="px-4 py-2.5 bg-[#151D33] hover:bg-[#1E294B] text-[#94A3B8] hover:text-white rounded-2xl text-xs font-bold border-2 border-[#1E294B] transition-colors cursor-pointer"
            title="Toggle between direct stream and embed player"
          >
            {selfHostedAvailable ? 'Switch to Embed' : 'Direct Play'}
          </button>

          {/* Stream Status Badge */}
          <span className="px-3.5 py-2 rounded-2xl bg-[#151D33] border-2 border-[#1E294B] text-xs font-bold text-[#94A3B8] hidden sm:inline-flex items-center gap-1.5">
            {selfHostedAvailable ? (
              <>
                <Zap className="w-3.5 h-3.5 text-[#FFB300]" />
                <span>Fast Stream</span>
              </>
            ) : (
              <>
                <Tv className="w-3.5 h-3.5 text-[#38BDF8]" />
                <span>Smart Stream</span>
              </>
            )}
          </span>
        </div>
      </div>

      {/* Video Description Box & Privacy Transparency */}
      <div className="mt-5 p-5 rounded-3xl bg-[#151D33] border-2 border-[#1E294B] text-sm text-[#94A3B8] leading-relaxed shadow-lg">
        <div className="flex items-center gap-3 font-bold text-white mb-2">
          <span>{video.views || 0} plays</span>
          <span>•</span>
          <span>Category: <span className="text-[#38BDF8] capitalize">{video.category_id}</span></span>
        </div>
        <p className="font-medium">
          Curated safe content verified for young learners and happy playtime.
        </p>
        <div className="mt-3 pt-3 border-t border-[#1E294B] text-xs">
          {selfHostedAvailable ? (
            <span className="text-[#10B981] font-bold inline-flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-[#10B981] shrink-0" />
              <span>Private Stream: Playing from your verified private storage. Zero external ad telemetry.</span>
            </span>
          ) : (
            <span className="inline-flex items-start gap-2 text-[#94A3B8]">
              <Info className="w-4 h-4 text-[#38BDF8] shrink-0 mt-0.5" />
              <span><strong>Kid-Safe Shield Active:</strong> External recommendations and distractions are automatically blocked for worry-free watching.</span>
            </span>
          )}
        </div>
      </div>
    </div>
  );
};

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
    <div className="mt-4 pb-6 border-b border-[#222222]">
      <h1 className="text-[18px] sm:text-[21px] font-bold leading-snug text-white">
        {cleanTitle}
      </h1>

      <div className="mt-3 flex flex-wrap items-center justify-between gap-4">
        {/* Channel Avatar & Info */}
        <div className="flex items-center gap-3">
          {avatarUrl ? (
            <img
              src={avatarUrl}
              alt={cleanChannelName}
              className="w-10 h-10 rounded-full object-cover bg-[#222222] border border-[#333333]"
            />
          ) : (
            <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-rose-600 to-amber-500 flex items-center justify-center text-white font-bold text-[14px]">
              {cleanChannelName.charAt(0).toUpperCase()}
            </div>
          )}

          <div className="flex flex-col">
            <span className="font-semibold text-white text-[15px] leading-tight">
              {cleanChannelName}
            </span>
            <span className="text-[12px] text-[#888888] capitalize">
              {video.category_id} • Safe Kids Content
            </span>
          </div>
        </div>

        {/* Actions & Badges */}
        <div className="flex items-center gap-2.5">
          {/* Favorite Button */}
          <button
            onClick={toggleFavorite}
            className={`flex items-center gap-2 px-4 py-2 rounded-full text-[13px] font-medium border transition-colors cursor-pointer ${
              isFavorite
                ? 'bg-[#FF0000] text-white border-[#FF0000]'
                : 'bg-[#222222] hover:bg-[#2c2c2c] text-[#F1F1F1] border-[#333333]'
            }`}
          >
            <Heart className={`w-4 h-4 ${isFavorite ? 'fill-current' : ''}`} />
            <span>{isFavorite ? 'Favorited' : 'Favorite'}</span>
          </button>

          {/* Mode Switcher */}
          <button
            onClick={() => setForceEmbed((prev) => !prev)}
            className="px-3.5 py-2 bg-[#1A1A1A] hover:bg-[#252525] text-[#AAAAAA] hover:text-white rounded-full text-[12px] border border-[#2D2D2D] transition-colors cursor-pointer"
            title="Toggle between self-hosted MP4 and YouTube player"
          >
            {selfHostedAvailable ? 'Switch to Embed' : 'Try Direct MP4'}
          </button>

          {/* Stream Status Badge */}
          <span className="px-3 py-1.5 rounded-full bg-[#161616] border border-[#262626] text-[11px] font-medium text-[#AAAAAA] hidden sm:inline-flex items-center gap-1.5">
            {selfHostedAvailable ? (
              <>
                <Zap className="w-3.5 h-3.5 text-amber-400" />
                <span>MP4 Fast Stream</span>
              </>
            ) : (
              <>
                <Tv className="w-3.5 h-3.5 text-red-500" />
                <span>YouTube Stream</span>
              </>
            )}
          </span>
        </div>
      </div>

      {/* Video Description Box & Privacy Transparency */}
      <div className="mt-4 p-4 rounded-2xl bg-[#1C1C1C] border border-[#2A2A2A] text-[13px] text-[#CCCCCC] leading-relaxed">
        <div className="flex items-center gap-3 font-semibold text-white mb-2">
          <span>{video.views || 0} views</span>
          <span>•</span>
          <span>Category: {video.category_id}</span>
        </div>
        <p>
          Curated content managed through parental controls.
        </p>
        <div className="mt-2.5 pt-2.5 border-t border-[#2A2A2A] text-[11px] text-[#999999]">
          {selfHostedAvailable ? (
            <span className="text-emerald-400 font-medium inline-flex items-center gap-1.5">
              <ShieldCheck className="w-4 h-4 text-emerald-400 shrink-0" />
              <span>Self-Hosted Stream: Playing from your verified private storage. Zero external telemetry sent to Google.</span>
            </span>
          ) : (
            <span className="inline-flex items-start gap-1.5">
              <Info className="w-4 h-4 text-[#888888] shrink-0 mt-0.5" />
              <span><strong>Privacy Notice:</strong> Playing via YouTube Privacy-Enhanced Mode (nocookie). Google receives standard request metadata (IP address, user agent, video ID) when streaming YouTube embeds. Self-hosted local/VPS playback is preferred once files are verified.</span>
            </span>
          )}
        </div>
      </div>
    </div>
  );
};

import React, { useState } from 'react';
import type { Video } from '../types/video';
import { getThumbnailUrl } from '../lib/constants';
import { Play, Zap } from 'lucide-react';

interface ShortsShelfProps {
  shorts: Video[];
  onPlayShort: (short: Video) => void;
}

export const ShortsShelf: React.FC<ShortsShelfProps> = ({ shorts, onPlayShort }) => {
  if (!shorts || shorts.length === 0) return null;

  return (
    <section className="my-8 px-4 sm:px-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-9 h-9 rounded-2xl bg-gradient-to-tr from-[#FF5E62] to-[#FFB300] text-white shadow-md shadow-[#FF5E62]/30 -rotate-3 hover:rotate-0 transition-transform">
            <Zap className="w-5 h-5 fill-current" />
          </div>
          <div>
            <h2 className="text-xl sm:text-2xl font-display font-black text-white tracking-wide flex items-center gap-2">
              Fun Reels
              <span className="text-xs px-2.5 py-0.5 rounded-full bg-[#FF5E62]/20 text-[#FF5E62] border border-[#FF5E62]/30 font-sans font-bold">
                Quick Bites
              </span>
            </h2>
            <p className="text-xs text-[#94A3B8] font-medium">Bite-sized smiles and mini adventures</p>
          </div>
        </div>
      </div>

      {/* Horizontal Scroll Shelf */}
      <div className="flex gap-4 sm:gap-5 overflow-x-auto pb-4 no-scrollbar scroll-smooth">
        {shorts.map((short) => (
          <ShortCard key={short.id} short={short} onPlay={onPlayShort} />
        ))}
      </div>
    </section>
  );
};

const ShortCard: React.FC<{ short: Video; onPlay: (s: Video) => void }> = ({ short, onPlay }) => {
  const [imgErr, setImgErr] = useState(false);
  const thumbUrl = getThumbnailUrl(short);

  return (
    <a
      href={`/shorts?v=${short.id}`}
      className="group relative flex-none w-[165px] sm:w-[195px] aspect-[9/16] rounded-[24px] overflow-hidden bg-[#151D33] cursor-pointer select-none border-2 border-[#1E294B] hover:border-[#FF5E62] transition-all duration-300 hover:shadow-xl hover:shadow-[#FF5E62]/20 hover:-translate-y-1 text-inherit no-underline"
    >
      {!imgErr ? (
        <img
          src={thumbUrl}
          alt={short.title}
          loading="lazy"
          onError={() => setImgErr(true)}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
        />
      ) : (
        <div className="w-full h-full flex flex-col items-center justify-center bg-[#151D33] text-[#64748B]">
          <Play className="w-10 h-10 opacity-60 text-[#FF5E62]" />
        </div>
      )}

      {/* Play Hover Overlay Bubble */}
      <div className="absolute inset-0 bg-gradient-to-t from-[#0B0F19]/95 via-[#0B0F19]/30 to-transparent flex flex-col justify-end p-3.5 pointer-events-none">
        <h4 className="text-[13px] font-bold text-white line-clamp-2 leading-snug drop-shadow-sm group-hover:text-[#FFB300] transition-colors">
          {short.title}
        </h4>
        <span className="text-[11px] text-[#94A3B8] mt-1 font-semibold truncate flex items-center gap-1.5">
          <span className="w-1.5 h-1.5 rounded-full bg-[#38BDF8]" />
          {short.channel_name || 'WonderKids Channel'}
        </span>
      </div>

      {/* Duration Pill */}
      <div className="absolute top-3 right-3 px-2 py-0.5 rounded-full bg-[#0B0F19]/80 backdrop-blur-md border border-white/10 text-[10px] font-black text-white shadow-sm">
        {short.duration_formatted || '00:30'}
      </div>
    </a>
  );
};

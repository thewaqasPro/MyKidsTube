import React, { useState } from 'react';
import type { Video } from '../types/video';
import { getThumbnailUrl } from '../lib/constants';
import { Play } from 'lucide-react';

interface ShortsShelfProps {
  shorts: Video[];
  onPlayShort: (short: Video) => void;
}

export const ShortsShelf: React.FC<ShortsShelfProps> = ({ shorts, onPlayShort }) => {
  if (!shorts || shorts.length === 0) return null;

  return (
    <section className="my-6 px-4 sm:px-6">
      {/* Header */}
      <div className="flex items-center gap-2.5 mb-4">
        <div className="flex items-center justify-center w-7 h-7 rounded-lg bg-[#FF0000] text-white">
          <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
            <path d="M17.77 10.32l-1.2-.5a3.86 3.86 0 00-.77-.24l1.43-.84a4.42 4.42 0 001.62-5.91 4.5 4.5 0 00-6.1-1.62l-7.2 4.22a4.42 4.42 0 00-1.62 5.91 4.5 4.5 0 006.1 1.62l1.2.5.77.24-1.43.84a4.42 4.42 0 00-1.62 5.91 4.5 4.5 0 006.1 1.62l7.2-4.22a4.42 4.42 0 001.62-5.91 4.5 4.5 0 00-6.1-1.62zM10 14.5v-5l4.5 2.5-4.5 2.5z" />
          </svg>
        </div>
        <h2 className="text-[19px] font-bold text-white tracking-tight">Shorts</h2>
        <span className="text-[12px] text-[#AAAAAA] ml-1">Quick & fun clips</span>
      </div>

      {/* Horizontal Scroll Shelf */}
      <div className="flex gap-4 overflow-x-auto pb-4 no-scrollbar scroll-smooth">
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
      className="group relative flex-none w-[160px] sm:w-[185px] aspect-[9/16] rounded-2xl overflow-hidden bg-[#202020] cursor-pointer select-none border border-[#262626] hover:border-[#383838] transition-all hover:scale-[1.02] active:scale-[0.98] text-inherit no-underline"
    >
      {!imgErr ? (
        <img
          src={thumbUrl}
          alt={short.title}
          loading="lazy"
          onError={() => setImgErr(true)}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
        />
      ) : (
        <div className="w-full h-full flex flex-col items-center justify-center bg-[#1c1c1c] text-[#717171]">
          <Play className="w-8 h-8 opacity-40 text-white" />
        </div>
      )}

      {/* Dark Gradient Overlay for Readability */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent flex flex-col justify-end p-3 pointer-events-none">
        <h4 className="text-[13px] font-medium text-white line-clamp-2 leading-tight drop-shadow-sm">
          {short.title}
        </h4>
        <span className="text-[11px] text-[#DDDDDD] mt-1 font-normal opacity-90 truncate">
          {short.channel_name || 'KidsTube Short'}
        </span>
      </div>

      {/* Duration Pill */}
      <div className="absolute top-2.5 right-2.5 px-1.5 py-0.5 rounded bg-black/70 text-[10px] font-bold text-white">
        {short.duration_formatted || '00:30'}
      </div>
    </a>
  );
};

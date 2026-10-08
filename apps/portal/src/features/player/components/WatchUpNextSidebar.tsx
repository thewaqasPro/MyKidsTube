import React from 'react';
import type { Video } from '@/types/video';
import { getYoutubeId } from '@/lib/constants';
import { Sparkles } from 'lucide-react';

interface WatchUpNextSidebarProps {
  relatedVideos: Video[];
}

export const WatchUpNextSidebar: React.FC<WatchUpNextSidebarProps> = ({ relatedVideos = [] }) => {
  return (
    <div className="w-full lg:w-96 shrink-0">
      <div className="flex items-center gap-2 mb-4">
        <h2 className="text-lg font-display font-black text-white tracking-wide">Up Next For You</h2>
        <Sparkles className="w-4 h-4 text-[#FFB300]" />
      </div>

      <div className="flex flex-col gap-3">
        {relatedVideos.slice(0, 15).map((rel) => {
          const relCleanTitle = rel.title.includes('•')
            ? rel.title.split('•').slice(1).join('•').trim()
            : rel.title;
          const relChannel =
            rel.channel_name ||
            (rel.title.includes('•') ? rel.title.split('•')[0].trim() : 'WonderKids');
          const thumb =
            rel.thumbnail_url ||
            `https://img.youtube.com/vi/${getYoutubeId(rel)}/mqdefault.jpg`;

          return (
            <a
              key={rel.id}
              href={`/watch/${rel.id}`}
              className="flex gap-3 group p-2 rounded-2xl bg-[#151D33]/40 hover:bg-[#151D33] border border-transparent hover:border-[#1E294B] transition-all duration-200 no-underline text-inherit"
            >
              {/* Thumbnail with duration badge */}
              <div className="relative w-36 sm:w-40 aspect-video rounded-xl overflow-hidden bg-[#0B0F19] shrink-0 border border-[#1E294B]">
                <img
                  src={thumb}
                  alt={relCleanTitle}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  loading="lazy"
                />
                <div className="absolute bottom-1.5 right-1.5 px-2 py-0.5 rounded-full bg-[#0B0F19]/80 backdrop-blur-md text-[10px] font-mono font-bold text-white border border-white/10">
                  {rel.duration_formatted || '03:00'}
                </div>
              </div>

              {/* Video Info */}
              <div className="flex flex-col min-w-0 py-0.5 justify-center">
                <h3 className="text-xs sm:text-[13px] font-bold text-white line-clamp-2 leading-snug group-hover:text-[#38BDF8] transition-colors">
                  {relCleanTitle}
                </h3>
                <span className="text-[11px] text-[#94A3B8] mt-1 font-semibold truncate">
                  {relChannel}
                </span>
                <span className="text-[10px] text-[#10B981] font-bold mt-1 inline-flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#10B981]" />
                  Verified Safe
                </span>
              </div>
            </a>
          );
        })}
      </div>
    </div>
  );
};

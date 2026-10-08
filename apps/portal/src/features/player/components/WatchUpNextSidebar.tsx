import React from 'react';
import type { Video } from '@/types/video';
import { getYoutubeId } from '@/lib/constants';

interface WatchUpNextSidebarProps {
  relatedVideos: Video[];
}

export const WatchUpNextSidebar: React.FC<WatchUpNextSidebarProps> = ({ relatedVideos = [] }) => {
  return (
    <div className="w-full lg:w-96 shrink-0">
      <h2 className="text-[16px] font-bold text-white mb-3">Up Next</h2>

      <div className="flex flex-col gap-3">
        {relatedVideos.slice(0, 15).map((rel) => {
          const relCleanTitle = rel.title.includes('•')
            ? rel.title.split('•').slice(1).join('•').trim()
            : rel.title;
          const relChannel =
            rel.channel_name ||
            (rel.title.includes('•') ? rel.title.split('•')[0].trim() : 'KidsTube');
          const thumb =
            rel.thumbnail_url ||
            `https://img.youtube.com/vi/${getYoutubeId(rel)}/mqdefault.jpg`;

          return (
            <a
              key={rel.id}
              href={`/watch/${rel.id}`}
              className="flex gap-3 group p-1.5 rounded-xl hover:bg-[#1E1E1E] transition-colors"
            >
              {/* Thumbnail with duration badge */}
              <div className="relative w-40 aspect-video rounded-lg overflow-hidden bg-[#222222] shrink-0 border border-[#2A2A2A]">
                <img
                  src={thumb}
                  alt={relCleanTitle}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
                  loading="lazy"
                />
                <div className="absolute bottom-1 right-1 px-1.5 py-0.5 rounded bg-black/85 text-[10px] font-mono font-medium text-white">
                  {rel.duration_formatted || '03:00'}
                </div>
              </div>

              {/* Video Info */}
              <div className="flex flex-col min-w-0 py-0.5">
                <h3 className="text-[13px] font-medium text-white line-clamp-2 leading-snug group-hover:text-[#3EA6FF] transition-colors">
                  {relCleanTitle}
                </h3>
                <span className="text-[11px] text-[#888888] mt-1 truncate">
                  {relChannel}
                </span>
                <span className="text-[10px] text-emerald-400 font-medium mt-0.5">
                  Safe Kid Video
                </span>
              </div>
            </a>
          );
        })}
      </div>
    </div>
  );
};

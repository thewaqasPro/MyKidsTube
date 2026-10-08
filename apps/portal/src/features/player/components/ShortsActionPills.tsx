import React from 'react';
import { ChevronUp, ChevronDown, Heart, Volume2, VolumeX } from 'lucide-react';

interface ShortsActionPillsProps {
  currentIndex: number;
  totalCount: number;
  isLiked: boolean;
  isMuted: boolean;
  handlePrev: () => void;
  handleNext: () => void;
  setIsLiked: React.Dispatch<React.SetStateAction<boolean>>;
  setIsMuted: React.Dispatch<React.SetStateAction<boolean>>;
}

export const ShortsActionPills: React.FC<ShortsActionPillsProps> = ({
  currentIndex,
  totalCount,
  isLiked,
  isMuted,
  handlePrev,
  handleNext,
  setIsLiked,
  setIsMuted,
}) => {
  return (
    <div className="flex flex-col items-center gap-3.5 z-30">
      <button
        onClick={handlePrev}
        disabled={currentIndex === 0}
        className="w-12 h-12 rounded-2xl bg-[#151D33] hover:bg-[#1E294B] disabled:opacity-20 disabled:pointer-events-none flex items-center justify-center text-white border-2 border-[#1E294B] transition-all cursor-pointer shadow-lg active:scale-90 hover:scale-105"
        title="Previous Short"
      >
        <ChevronUp className="w-6 h-6 text-[#38BDF8]" />
      </button>

      <button
        onClick={() => setIsLiked((prev) => !prev)}
        className={`w-12 h-12 rounded-2xl flex flex-col items-center justify-center border-2 transition-all cursor-pointer shadow-lg active:scale-90 hover:scale-105 ${
          isLiked
            ? 'bg-gradient-to-r from-[#FF5E62] to-[#FF8E53] text-white border-[#FF5E62] shadow-[#FF5E62]/40'
            : 'bg-[#151D33] hover:bg-[#1E294B] text-white border-[#1E294B]'
        }`}
        title="Favorite this short"
      >
        <Heart className={`w-5 h-5 ${isLiked ? 'fill-current' : 'text-[#FF5E62]'}`} />
      </button>

      <button
        onClick={() => setIsMuted((prev) => !prev)}
        className="w-12 h-12 rounded-2xl bg-[#151D33] hover:bg-[#1E294B] flex items-center justify-center text-white border-2 border-[#1E294B] transition-all cursor-pointer shadow-lg active:scale-90 hover:scale-105"
        title={isMuted ? 'Unmute' : 'Mute'}
      >
        {isMuted ? <VolumeX className="w-5 h-5 text-[#FF5E62]" /> : <Volume2 className="w-5 h-5 text-[#FFB300]" />}
      </button>

      <button
        onClick={handleNext}
        disabled={currentIndex === totalCount - 1}
        className="w-12 h-12 rounded-2xl bg-[#151D33] hover:bg-[#1E294B] disabled:opacity-20 disabled:pointer-events-none flex items-center justify-center text-white border-2 border-[#1E294B] transition-all cursor-pointer shadow-lg active:scale-90 hover:scale-105"
        title="Next Short"
      >
        <ChevronDown className="w-6 h-6 text-[#38BDF8]" />
      </button>

      <div className="mt-1 px-3 py-1 rounded-full bg-[#151D33] border border-[#1E294B] text-xs font-mono font-bold text-[#94A3B8] text-center shadow-sm">
        {currentIndex + 1}/{totalCount}
      </div>
    </div>
  );
};

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
    <div className="flex flex-col items-center gap-3 z-30">
      <button
        onClick={handlePrev}
        disabled={currentIndex === 0}
        className="w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-[#1F1F1F] hover:bg-[#2C2C2C] disabled:opacity-25 disabled:pointer-events-none flex items-center justify-center text-white border border-[#333333] transition-all cursor-pointer shadow-xl active:scale-90"
        title="Previous Short"
      >
        <ChevronUp className="w-6 h-6" />
      </button>

      <button
        onClick={() => setIsLiked((prev) => !prev)}
        className={`w-11 h-11 sm:w-12 sm:h-12 rounded-full flex flex-col items-center justify-center border transition-all cursor-pointer shadow-xl active:scale-90 ${
          isLiked
            ? 'bg-[#FF0000] text-white border-[#FF0000]'
            : 'bg-[#1F1F1F] hover:bg-[#2C2C2C] text-white border-[#333333]'
        }`}
        title="Favorite this short"
      >
        <Heart className={`w-5 h-5 ${isLiked ? 'fill-current' : ''}`} />
      </button>

      <button
        onClick={() => setIsMuted((prev) => !prev)}
        className="w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-[#1F1F1F] hover:bg-[#2C2C2C] flex items-center justify-center text-white border border-[#333333] transition-all cursor-pointer shadow-xl active:scale-90"
        title={isMuted ? 'Unmute' : 'Mute'}
      >
        {isMuted ? <VolumeX className="w-5 h-5 text-[#FF0000]" /> : <Volume2 className="w-5 h-5" />}
      </button>

      <button
        onClick={handleNext}
        disabled={currentIndex === totalCount - 1}
        className="w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-[#1F1F1F] hover:bg-[#2C2C2C] disabled:opacity-25 disabled:pointer-events-none flex items-center justify-center text-white border border-[#333333] transition-all cursor-pointer shadow-xl active:scale-90"
        title="Next Short"
      >
        <ChevronDown className="w-6 h-6" />
      </button>

      <div className="mt-1 px-2.5 py-1 rounded-full bg-[#181818] border border-[#2D2D2D] text-[11px] font-mono text-[#AAAAAA] text-center">
        {currentIndex + 1}/{totalCount}
      </div>
    </div>
  );
};

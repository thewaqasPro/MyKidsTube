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
        className="w-12 h-12 rounded-2xl bg-surface hover:bg-surface-hover disabled:opacity-20 disabled:pointer-events-none flex items-center justify-center text-white border-2 border-border transition-all cursor-pointer shadow-lg"
        title="Previous Short"
      >
        <ChevronUp className="w-6 h-6 text-sky" />
      </button>

      <button
        onClick={() => setIsLiked((prev) => !prev)}
        className={`w-12 h-12 rounded-2xl flex flex-col items-center justify-center border-2 transition-all cursor-pointer shadow-lg ${
          isLiked
            ? 'bg-gradient-to-r from-coral to-coral-hover text-white border-coral shadow-coral/40'
            : 'bg-surface hover:bg-surface-hover text-white border-border'
        }`}
        title="Favorite this short"
      >
        <Heart className={`w-5 h-5 ${isLiked ? 'fill-current' : 'text-coral'}`} />
      </button>

      <button
        onClick={() => setIsMuted((prev) => !prev)}
        className="w-12 h-12 rounded-2xl bg-surface hover:bg-surface-hover flex items-center justify-center text-white border-2 border-border transition-all cursor-pointer shadow-lg"
        title={isMuted ? 'Unmute' : 'Mute'}
      >
        {isMuted ? <VolumeX className="w-5 h-5 text-coral" /> : <Volume2 className="w-5 h-5 text-sun" />}
      </button>

      <button
        onClick={handleNext}
        disabled={currentIndex === totalCount - 1}
        className="w-12 h-12 rounded-2xl bg-surface hover:bg-surface-hover disabled:opacity-20 disabled:pointer-events-none flex items-center justify-center text-white border-2 border-border transition-all cursor-pointer shadow-lg"
        title="Next Short"
      >
        <ChevronDown className="w-6 h-6 text-sky" />
      </button>

      <div className="mt-1 px-3 py-1 rounded-full bg-surface border border-border text-xs font-mono font-bold text-text-secondary text-center shadow-sm">
        {currentIndex + 1}/{totalCount}
      </div>
    </div>
  );
};

import React, { useEffect, useRef, useState } from 'react';
import type { Video } from '../types/video';
import { getStreamUrl, getChannelIconUrl } from '../lib/constants';
import { X, ChevronUp, ChevronDown, Volume2, VolumeX } from 'lucide-react';

interface ShortsModalProps {
  shorts: Video[];
  initialIndex: number;
  onClose: () => void;
}

export const ShortsModal: React.FC<ShortsModalProps> = ({
  shorts,
  initialIndex,
  onClose,
}) => {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [isMuted, setIsMuted] = useState(false);
  const videoRef = useRef<HTMLVideoElement | null>(null);

  const currentShort = shorts[currentIndex] || shorts[0];

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      if (e.key === 'ArrowDown') handleNext();
      if (e.key === 'ArrowUp') handlePrev();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [currentIndex, shorts.length]);

  useEffect(() => {
    if (videoRef.current) {
      videoRef.current.currentTime = 0;
      videoRef.current.play().catch(() => {});
    }
  }, [currentIndex]);

  const handleNext = () => {
    if (currentIndex < shorts.length - 1) {
      setCurrentIndex((prev) => prev + 1);
    }
  };

  const handlePrev = () => {
    if (currentIndex > 0) {
      setCurrentIndex((prev) => prev - 1);
    }
  };

  const toggleMute = () => {
    if (!videoRef.current) return;
    videoRef.current.muted = !videoRef.current.muted;
    setIsMuted(videoRef.current.muted);
  };

  if (!currentShort) return null;

  const streamUrl = getStreamUrl(currentShort);
  const avatarUrl = getChannelIconUrl(currentShort);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/95 backdrop-blur-md p-2">
      {/* Close button */}
      <button
        onClick={onClose}
        className="fixed top-4 right-4 z-50 p-2.5 rounded-full bg-[#222222]/80 hover:bg-[#333333] text-white transition-all cursor-pointer shadow-lg"
        title="Close (Esc)"
      >
        <X className="w-5 h-5" />
      </button>

      <div className="relative flex items-center gap-4 max-h-[90vh]">
        {/* Vertical Reel Player Container */}
        <div className="relative h-[85vh] max-h-[820px] aspect-[9/16] rounded-3xl overflow-hidden bg-black shadow-2xl border border-[#272727] flex items-center justify-center">
          <video
            ref={videoRef}
            src={streamUrl}
            autoPlay
            loop
            playsInline
            muted={isMuted}
            className="w-full h-full object-cover cursor-pointer"
            onClick={() => {
              if (videoRef.current) {
                if (videoRef.current.paused) videoRef.current.play();
                else videoRef.current.pause();
              }
            }}
          />

          {/* Sound Toggle Button */}
          <button
            onClick={toggleMute}
            className="absolute top-4 right-4 p-2 rounded-full bg-black/60 text-white hover:bg-black/80 transition-colors"
          >
            {isMuted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
          </button>

          {/* Bottom Info Overlay */}
          <div className="absolute inset-x-0 bottom-0 p-5 bg-gradient-to-t from-black/90 via-black/40 to-transparent flex flex-col pointer-events-none">
            <div className="flex items-center gap-2 mb-2">
              {avatarUrl ? (
                <img
                  src={avatarUrl}
                  alt={currentShort.channel_name}
                  className="w-8 h-8 rounded-full object-cover border border-white/20"
                />
              ) : (
                <div className="w-8 h-8 rounded-full bg-red-600 flex items-center justify-center text-white text-xs font-bold">
                  K
                </div>
              )}
              <span className="text-[13px] font-semibold text-white drop-shadow">
                {currentShort.channel_name || 'KidsTube'}
              </span>
            </div>

            <p className="text-[14px] font-medium text-white line-clamp-2 leading-snug drop-shadow">
              {currentShort.title}
            </p>
          </div>
        </div>

        {/* Navigation Buttons on Right */}
        <div className="hidden sm:flex flex-col gap-3">
          <button
            onClick={handlePrev}
            disabled={currentIndex === 0}
            className={`p-3 rounded-full bg-[#222222] text-white hover:bg-[#333333] transition-all cursor-pointer ${
              currentIndex === 0 ? 'opacity-30 cursor-not-allowed' : ''
            }`}
            title="Previous Short (Up Arrow)"
          >
            <ChevronUp className="w-6 h-6" />
          </button>
          <button
            onClick={handleNext}
            disabled={currentIndex >= shorts.length - 1}
            className={`p-3 rounded-full bg-[#222222] text-white hover:bg-[#333333] transition-all cursor-pointer ${
              currentIndex >= shorts.length - 1 ? 'opacity-30 cursor-not-allowed' : ''
            }`}
            title="Next Short (Down Arrow)"
          >
            <ChevronDown className="w-6 h-6" />
          </button>
        </div>
      </div>
    </div>
  );
};

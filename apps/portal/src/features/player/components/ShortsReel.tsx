import React from 'react';
import type { Video } from '@/types/video';
import { getStreamUrl, getThumbnailUrl } from '@/lib/constants';
import { ArrowRight } from 'lucide-react';
import '@videojs/react/video/neutral-skin.css';
import { VideoPlayer, NeutralVideoSkin, Video as VideoElement } from '@videojs/react/video';
import { YouTubeVideo } from '@videojs/react/media/youtube-video';

interface ShortsReelProps {
  currentShort: Video;
  selfHosted: boolean;
  videoRef: React.RefObject<HTMLVideoElement | null>;
  iframeRef: React.RefObject<HTMLIFrameElement | null>;
  embedUrl: string;
  isMuted: boolean;
  isScrubbing: boolean;
  setIsScrubbing: (s: boolean) => void;
  currentTime: number;
  setCurrentTime: (t: number) => void;
  duration: number;
  setDuration: (d: number) => void;
  handleTouchStart: (e: React.TouchEvent) => void;
  handleTouchEnd: (e: React.TouchEvent) => void;
  handleScreenTap: (e: React.MouseEvent) => void;
  handleScrubberChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  tapToNextEnabled: boolean;
  advanceFeedback: boolean;
  formatSeconds: (s: number) => string;
}

export const ShortsReel: React.FC<ShortsReelProps> = ({
  currentShort,
  selfHosted,
  videoRef,
  iframeRef,
  embedUrl,
  isMuted,
  isScrubbing,
  setIsScrubbing,
  currentTime,
  setCurrentTime,
  duration,
  setDuration,
  handleTouchStart,
  handleTouchEnd,
  handleScreenTap,
  handleScrubberChange,
  tapToNextEnabled,
  advanceFeedback,
  formatSeconds,
}) => {
  const youtubeUrl = currentShort.youtube_id
    ? `https://www.youtube.com/watch?v=${currentShort.youtube_id}`
    : currentShort.source_url || `https://www.youtube.com/watch?v=${currentShort.id}`;

  return (
    <div
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
      data-reel-container="true"
      className="relative h-full aspect-[9/16] rounded-[32px] overflow-hidden bg-canvas-deep flex items-center justify-center select-none"
    >
      <VideoPlayer
        key={currentShort.id}
        poster={getThumbnailUrl(currentShort)}
        title=""
      >
        <NeutralVideoSkin className="overflow-hidden w-full h-full" style={{ width: '100%', height: '100%', aspectRatio: '9 / 16' }}>
          {selfHosted ? (
            <VideoElement
              ref={videoRef}
              src={getStreamUrl(currentShort)}
              autoPlay
              loop
              playsInline
              muted={isMuted}
              onTimeUpdate={() => {
                if (videoRef.current && !isScrubbing) {
                  setCurrentTime(videoRef.current.currentTime);
                }
              }}
              onLoadedMetadata={() => {
                if (videoRef.current) {
                  setDuration(videoRef.current.duration);
                }
              }}
              className="w-full h-full object-cover"
            />
          ) : (
            <YouTubeVideo
              src={youtubeUrl}
              autoPlay
              loop
              playsInline
              muted={isMuted}
              controls={false}
              source={{
                src: youtubeUrl,
                engine: {
                  youtube: {
                    controls: 0,
                    rel: 0,
                    iv_load_policy: 3,
                    disablekb: 1,
                    fs: 0,
                  },
                },
              }}
            />
          )}
        </NeutralVideoSkin>
      </VideoPlayer>

      {/* SHIELD 1: Top Blocker (Blocks title, channel avatar & share button) */}
      <div
        onClick={handleScreenTap}
        className="absolute top-0 inset-x-0 h-24 z-30 bg-gradient-to-b from-canvas-deep/80 via-canvas-deep/30 to-transparent cursor-pointer"
        title="Kid Safe Shield: Top External Links Blocked"
      />

      {/* SHIELD 2: Center Touch-to-Next Advance Zone */}
      {tapToNextEnabled && (
        <div
          onClick={handleScreenTap}
          className="absolute inset-x-0 top-20 bottom-16 z-20 bg-transparent cursor-pointer flex items-center justify-center"
        />
      )}

      {/* Animated Kid Touch Visual Feedback */}
      {advanceFeedback && (
        <div className="absolute inset-0 z-40 flex items-center justify-center pointer-events-none">

          <div className="px-6 py-3.5 rounded-3xl bg-gradient-to-r from-coral to-sun text-white flex items-center gap-3 shadow-2xl shadow-coral/50 animate-bounce border-2 border-white/20">
            <span className="text-sm font-display font-black tracking-wide">Next Fun Reel! 🚀</span>
            <ArrowRight className="w-5 h-5 text-white" />
          </div>
        </div>
      )}

      {/* Video Title & Channel Metadata Overlay */}
      <div className="hidden absolute inset-x-0 bottom-8 p-4 bg-gradient-to-t from-canvas-deep/95 via-canvas-deep/60 to-transparent pointer-events-none z-20">
        <h2 className="text-sm sm:text-base font-display font-bold text-white drop-shadow-md line-clamp-2">
          {currentShort.title}
        </h2>
        <div className="flex items-center gap-2 mt-2">
          <span className="text-xs text-text-secondary font-semibold truncate">
            {currentShort.channel_name || 'WonderKids Channel'}
          </span>
          <span className="px-2 py-0.5 rounded-full bg-mint/20 text-mint text-[10px] font-bold border border-mint/30">
            Safe
          </span>
          {tapToNextEnabled && (
            <span className="text-[10px] text-sun font-bold">
              • Tap screen for next
            </span>
          )}
        </div>
      </div>

      {/* Kid-Safe Position / Progress Slider */}
      <div
        onClick={(e) => e.stopPropagation()}
        onTouchStart={(e) => e.stopPropagation()}
        onTouchEnd={(e) => e.stopPropagation()}
        className="hidden absolute inset-x-0 bottom-0 z-35 px-4 pb-2.5 pt-4 bg-gradient-to-t from-canvas-deep/95 to-transparent flex flex-col gap-1 select-none"
      >
        <div className="relative flex items-center group/slider py-1">
          <input
            type="range"
            min="0"
            max={duration || 60}
            step="0.5"
            value={currentTime}
            onMouseDown={() => setIsScrubbing(true)}
            onMouseUp={() => setIsScrubbing(false)}
            onTouchStart={() => setIsScrubbing(true)}
            onTouchEnd={() => setIsScrubbing(false)}
            onChange={handleScrubberChange}
            className="w-full h-1.5 sm:h-2 bg-border accent-coral hover:h-2.5 transition-all rounded-full appearance-none cursor-pointer"
            title="Position Progress Slider"
          />
        </div>
        <div className="flex items-center justify-between text-[10px] font-mono font-bold text-text-secondary px-1">
          <span>{formatSeconds(currentTime)}</span>
          <span>{formatSeconds(duration)}</span>
        </div>
      </div>
    </div>
  );
};

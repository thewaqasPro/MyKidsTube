import React from 'react';
import type { Video } from '@/types/video';
import {
  Play,
  Pause,
  Volume2,
  VolumeX,
  Maximize,
  RotateCcw,
  Layers
} from 'lucide-react';

interface WatchPlayerProps {
  video: Video;
  selfHostedAvailable: boolean;
  streamUrl: string;
  embedUrl: string;
  isPlaying: boolean;
  isMuted: boolean;
  currentTime: number;
  duration: number;
  isTheater: boolean;
  setIsTheater: React.Dispatch<React.SetStateAction<boolean>>;
  setStreamError: (err: boolean) => void;
  setCurrentTime: (time: number) => void;
  setDuration: (dur: number) => void;
  setIsPlaying: (playing: boolean) => void;
  videoRef: React.RefObject<HTMLVideoElement | null>;
  togglePlay: () => void;
  toggleMute: () => void;
  toggleFullscreen: () => void;
  handleSeek: (e: React.ChangeEvent<HTMLInputElement>) => void;
  formatSeconds: (sec: number) => string;
}

export const WatchPlayer: React.FC<WatchPlayerProps> = ({
  video,
  selfHostedAvailable,
  streamUrl,
  embedUrl,
  isPlaying,
  isMuted,
  currentTime,
  duration,
  isTheater,
  setIsTheater,
  setStreamError,
  setCurrentTime,
  setDuration,
  setIsPlaying,
  videoRef,
  togglePlay,
  toggleMute,
  toggleFullscreen,
  handleSeek,
  formatSeconds,
}) => {
  return (
    <div
      id="player-container"
      className="relative aspect-video w-full rounded-[28px] overflow-hidden bg-canvas-deep shadow-2xl border-2 border-border group"
    >
      {selfHostedAvailable ? (
        // MODE A: Native Self-Hosted HTML5 MP4 Player
        <>
          <video
            ref={videoRef}
            src={streamUrl}
            autoPlay
            playsInline
            muted={isMuted}
            onError={() => {
              console.warn('Local MP4 stream unreachable, falling back to YouTube Embed');
              setStreamError(true);
            }}
            onTimeUpdate={() => {
              if (videoRef.current) setCurrentTime(videoRef.current.currentTime);
            }}
            onLoadedMetadata={() => {
              if (videoRef.current) setDuration(videoRef.current.duration);
            }}
            onEnded={() => setIsPlaying(false)}
            className="w-full h-full object-contain cursor-pointer"
            onClick={togglePlay}
          />

          {/* Custom Control Bar Overlay */}
          <div className="absolute inset-x-0 bottom-0 p-4 bg-gradient-to-t from-canvas-deep/95 via-canvas-deep/60 to-transparent flex flex-col gap-2.5 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
            <input
              type="range"
              min="0"
              max={duration || 100}
              value={currentTime}
              onChange={handleSeek}
              className="w-full h-2 bg-border accent-coral rounded-full appearance-none cursor-pointer hover:h-2.5 transition-all"
            />

            <div className="flex items-center justify-between text-white text-[13px]">
              <div className="flex items-center gap-4">
                <button
                  onClick={togglePlay}
                  className="w-9 h-9 rounded-full bg-white/10 hover:bg-coral text-white flex items-center justify-center transition-all cursor-pointer shadow-md"
                  title={isPlaying ? 'Pause' : 'Play'}
                >
                  {isPlaying ? <Pause className="w-4 h-4 fill-current" /> : <Play className="w-4 h-4 fill-current ml-0.5" />}
                </button>
                <button
                  onClick={toggleMute}
                  className="w-9 h-9 rounded-full bg-white/10 hover:bg-sky text-white flex items-center justify-center transition-all cursor-pointer"
                  title={isMuted ? 'Unmute' : 'Mute'}
                >
                  {isMuted ? <VolumeX className="w-4 h-4 text-coral" /> : <Volume2 className="w-4 h-4" />}
                </button>
                <span className="text-xs text-text-secondary font-bold tracking-wider font-mono bg-surface/80 px-2.5 py-1 rounded-full border border-white/5">
                  {formatSeconds(currentTime)} / {formatSeconds(duration || video.duration)}
                </span>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => {
                    if (videoRef.current) videoRef.current.currentTime = 0;
                  }}
                  title="Replay from start"
                  className="w-8 h-8 rounded-full hover:bg-white/10 text-text-secondary hover:text-white flex items-center justify-center transition-colors cursor-pointer"
                >
                  <RotateCcw className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setIsTheater((prev) => !prev)}
                  title="Theater Mode"
                  className="w-8 h-8 rounded-full hover:bg-white/10 text-text-secondary hover:text-white hidden sm:flex items-center justify-center transition-colors cursor-pointer"
                >
                  <Layers className="w-4 h-4" />
                </button>
                <button
                  onClick={toggleFullscreen}
                  title="Fullscreen"
                  className="w-8 h-8 rounded-full hover:bg-white/10 text-text-secondary hover:text-white flex items-center justify-center transition-colors cursor-pointer"
                >
                  <Maximize className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </>
      ) : (
        // MODE B: YouTube Privacy-Enhanced Embed with Kid-Safe Click-Blocking Shields
        <div className="relative w-full h-full overflow-hidden flex items-center justify-center">
          <iframe
            src={embedUrl}
            title={video.title}
            className="w-full h-full border-0 pointer-events-auto transform scale-x-[1.03] scale-y-[1.2] origin-center"
            sandbox="allow-scripts allow-same-origin allow-presentation"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />

          {/* SHIELD 1: Top Blocker (Blocks YouTube title, channel link & share button) */}
          {/* <div
            className="absolute top-0 inset-x-0 h-16 z-30 bg-transparent cursor-default"
            title="Kid Safe Shield: Top External Links Blocked"
          /> */}

          {/* SHIELD 2: Bottom Blocker (Blocks YouTube logo & settings gear) */}
          {/* <div
            className="absolute bottom-0 inset-x-0 h-16 z-30 bg-transparent cursor-default"
            title="Kid Safe Shield: Bottom YouTube Controls Blocked"
          /> */}
        </div>
      )}
    </div>
  );
};

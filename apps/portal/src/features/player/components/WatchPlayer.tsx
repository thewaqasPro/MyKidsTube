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
      className="relative aspect-video w-full rounded-2xl overflow-hidden bg-black shadow-2xl border border-[#222222] group"
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
          <div className="absolute inset-x-0 bottom-0 p-3 bg-gradient-to-t from-black/90 via-black/50 to-transparent flex flex-col gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
            <input
              type="range"
              min="0"
              max={duration || 100}
              value={currentTime}
              onChange={handleSeek}
              className="w-full h-1.5 bg-[#444444] accent-[#FF0000] rounded-lg appearance-none cursor-pointer"
            />

            <div className="flex items-center justify-between text-white text-[13px]">
              <div className="flex items-center gap-4">
                <button onClick={togglePlay} className="hover:text-[#FF0000] transition-colors cursor-pointer">
                  {isPlaying ? <Pause className="w-5 h-5 fill-current" /> : <Play className="w-5 h-5 fill-current" />}
                </button>
                <button onClick={toggleMute} className="hover:text-white transition-colors cursor-pointer">
                  {isMuted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
                </button>
                <span className="text-[12px] text-[#DDDDDD] font-mono">
                  {formatSeconds(currentTime)} / {formatSeconds(duration || video.duration)}
                </span>
              </div>

              <div className="flex items-center gap-3">
                <button
                  onClick={() => {
                    if (videoRef.current) videoRef.current.currentTime = 0;
                  }}
                  title="Replay"
                  className="hover:text-white cursor-pointer"
                >
                  <RotateCcw className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setIsTheater((prev) => !prev)}
                  title="Toggle Theater Mode (T)"
                  className="hover:text-white hidden sm:inline cursor-pointer"
                >
                  <Layers className="w-4 h-4" />
                </button>
                <button onClick={toggleFullscreen} title="Fullscreen (F)" className="hover:text-white cursor-pointer">
                  <Maximize className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </>
      ) : (
        // MODE B: YouTube Privacy-Enhanced Embed with Kid-Safe Click-Blocking Shields
        <div className="relative w-full h-full">
          <iframe
            src={embedUrl}
            title={video.title}
            className="w-full h-full border-0 pointer-events-auto"
            sandbox="allow-scripts allow-same-origin allow-presentation"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />

          {/* SHIELD 1: Top Blocker (Blocks YouTube title, channel link & share button) */}
          <div 
            className="absolute top-0 inset-x-0 h-18 z-30 bg-transparent cursor-default"
            title="Kid Safe Shield: Top External Links Blocked"
          />

          {/* SHIELD 2: Bottom-Right Blocker (Blocks YouTube logo & settings gear) */}
          <div 
            className="absolute bottom-0 right-0 w-36 h-14 z-30 bg-transparent cursor-default"
            title="Kid Safe Shield: YouTube Logo & Settings Blocked"
          />
        </div>
      )}
    </div>
  );
};

import React from 'react';
import type { Video } from '@/types/video';
import '@videojs/react/video/neutral-skin.css';
import { VideoPlayer, NeutralVideoSkin, Video as VideoElement } from '@videojs/react/video';
import { YouTubeVideo } from '@videojs/react/media/youtube-video';
import { getThumbnailUrl } from '@/lib/constants';
import { Layers } from 'lucide-react';

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
  const youtubeUrl = video.youtube_id
    ? `https://www.youtube.com/watch?v=${video.youtube_id}`
    : video.source_url || `https://www.youtube.com/watch?v=${video.id}`;

  return (
    <div
      id="player-container"
      className="relative aspect-video w-full rounded-[28px] overflow-hidden bg-canvas-deep shadow-2xl border-2 border-border group"
    >
      <VideoPlayer
        key={video.id}
        poster={getThumbnailUrl(video)}
        title=""
      >
        <NeutralVideoSkin className="overflow-hidden w-full h-full" style={{ width: '100%', height: '100%', aspectRatio: '16 / 9' }}>
          {selfHostedAvailable && streamUrl ? (
            <VideoElement
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
            />
          ) : (
            <YouTubeVideo
              src={youtubeUrl}
              autoPlay
              playsInline
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

      {/* Kid-Safe Top Shield: Blocks any click on YouTube title, channel & share links */}
      <div
        className="absolute top-0 inset-x-0 h-16 z-20 bg-gradient-to-b from-canvas-deep/80 via-canvas-deep/30 to-transparent cursor-default pointer-events-auto"
        title="Kid Safe Shield: External Links Blocked"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
      />

      {/* Floating Theater Mode Toggle */}
      <button
        onClick={() => setIsTheater((prev) => !prev)}
        title={isTheater ? 'Default view' : 'Theater mode'}
        className="absolute top-4 right-4 z-30 w-9 h-9 rounded-full bg-canvas-deep/80 hover:bg-canvas-deep text-text-secondary hover:text-white backdrop-blur-md hidden sm:flex items-center justify-center transition-all cursor-pointer shadow-lg border border-white/10 opacity-0 group-hover:opacity-100"
      >
        <Layers className="w-4 h-4" />
      </button>
    </div>
  );
};

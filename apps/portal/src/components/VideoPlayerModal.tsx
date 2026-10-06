import React, { useEffect, useRef, useState } from 'react';
import type { Video } from '../types/video';
import { getStreamUrl, getThumbnailUrl, getChannelIconUrl } from '../lib/constants';
import { X, Play, Pause, Volume2, VolumeX, Maximize, RotateCcw } from 'lucide-react';

interface VideoPlayerModalProps {
  video: Video | null;
  onClose: () => void;
  onSelectVideo: (video: Video) => void;
  relatedVideos: Video[];
}

export const VideoPlayerModal: React.FC<VideoPlayerModalProps> = ({
  video,
  onClose,
  onSelectVideo,
  relatedVideos,
}) => {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const [isPlaying, setIsPlaying] = useState(true);
  const [isMuted, setIsMuted] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      if (e.key === ' ' && videoRef.current) {
        e.preventDefault();
        togglePlay();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose]);

  useEffect(() => {
    if (video && videoRef.current) {
      videoRef.current.currentTime = 0;
      videoRef.current.play().catch(() => setIsPlaying(false));
      setIsPlaying(true);
    }
  }, [video]);

  if (!video) return null;

  const streamUrl = getStreamUrl(video);
  const avatarUrl = getChannelIconUrl(video);
  const cleanChannelName = video.channel_name || (video.title.includes('•') ? video.title.split('•')[0].trim() : 'KidsTube');
  const cleanTitle = video.title.includes('•') ? video.title.split('•').slice(1).join('•').trim() : video.title;

  const togglePlay = () => {
    if (!videoRef.current) return;
    if (videoRef.current.paused) {
      videoRef.current.play();
      setIsPlaying(true);
    } else {
      videoRef.current.pause();
      setIsPlaying(false);
    }
  };

  const toggleMute = () => {
    if (!videoRef.current) return;
    videoRef.current.muted = !videoRef.current.muted;
    setIsMuted(videoRef.current.muted);
  };

  const toggleFullscreen = () => {
    if (!videoRef.current) return;
    if (document.fullscreenElement) {
      document.exitFullscreen();
    } else {
      videoRef.current.requestFullscreen();
    }
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const targetTime = Number(e.target.value);
    if (videoRef.current) {
      videoRef.current.currentTime = targetTime;
      setCurrentTime(targetTime);
    }
  };

  const formatSeconds = (sec: number) => {
    const m = Math.floor(sec / 60);
    const s = Math.floor(sec % 60);
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/95 backdrop-blur-md p-2 sm:p-4 overflow-y-auto">
      {/* Close button */}
      <button
        onClick={onClose}
        className="fixed top-4 right-4 z-50 p-2.5 rounded-full bg-[#222222]/80 hover:bg-[#333333] text-white transition-all cursor-pointer shadow-lg"
        title="Close (Esc)"
      >
        <X className="w-5 h-5" />
      </button>

      <div className="w-full max-w-6xl my-auto flex flex-col lg:flex-row gap-6 pt-12 lg:pt-0">
        {/* Main Player Column */}
        <div className="flex-1 flex flex-col">
          {/* 16:9 Video Player Container */}
          <div className="relative aspect-video w-full rounded-2xl overflow-hidden bg-black shadow-2xl border border-[#222222] group">
            <video
              ref={videoRef}
              src={streamUrl}
              autoPlay
              playsInline
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
              {/* YouTube Red Scrubber Bar */}
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
                  <button onClick={togglePlay} className="hover:text-[#FF0000] transition-colors">
                    {isPlaying ? <Pause className="w-5 h-5 fill-current" /> : <Play className="w-5 h-5 fill-current" />}
                  </button>
                  <button onClick={toggleMute} className="hover:text-white transition-colors">
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
                    className="hover:text-white"
                  >
                    <RotateCcw className="w-4 h-4" />
                  </button>
                  <button onClick={toggleFullscreen} className="hover:text-white">
                    <Maximize className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Video Metadata */}
          <div className="mt-4 flex flex-col">
            <h1 className="text-[18px] sm:text-[20px] font-bold text-white leading-snug">
              {cleanTitle || video.title}
            </h1>

            <div className="mt-3 flex items-center justify-between border-b border-[#282828] pb-4">
              <div className="flex items-center gap-3">
                {avatarUrl ? (
                  <img
                    src={avatarUrl}
                    alt={cleanChannelName}
                    className="w-10 h-10 rounded-full object-cover bg-[#222] border border-[#333]"
                  />
                ) : (
                  <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-rose-500 to-amber-500 flex items-center justify-center text-white text-[14px] font-bold">
                    {cleanChannelName.charAt(0).toUpperCase()}
                  </div>
                )}
                <div>
                  <h3 className="text-[14px] font-semibold text-white">{cleanChannelName}</h3>
                  <p className="text-[11px] text-[#888888]">100% Curated Safe Video</p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span className="px-3 py-1 rounded-full bg-[#222222] text-[#3EA6FF] text-[12px] font-medium border border-[#303030]">
                  HD 720p
                </span>
                <span className="px-3 py-1 rounded-full bg-[#222222] text-[#00E676] text-[12px] font-medium border border-[#303030]">
                  Ad-Free
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Related Shelf Sidebar */}
        <div className="w-full lg:w-80 flex flex-col">
          <h3 className="text-[15px] font-bold text-white mb-3 tracking-tight">More Safe Videos</h3>
          <div className="flex flex-col gap-3 max-h-[500px] overflow-y-auto pr-1 no-scrollbar">
            {relatedVideos
              .filter((v) => v.id !== video.id)
              .slice(0, 8)
              .map((rel) => (
                <div
                  key={rel.id}
                  onClick={() => onSelectVideo(rel)}
                  className="flex gap-2.5 p-1.5 rounded-xl hover:bg-[#222222] cursor-pointer transition-colors group"
                >
                  <div className="relative w-32 aspect-video rounded-lg overflow-hidden bg-[#202020] shrink-0 border border-[#2a2a2a]">
                    <img
                      src={getThumbnailUrl(rel)}
                      alt={rel.title}
                      loading="lazy"
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                    />
                    <div className="absolute bottom-1 right-1 px-1 py-0.2 rounded bg-black/80 text-[10px] font-bold text-white">
                      {rel.duration_formatted}
                    </div>
                  </div>
                  <div className="flex flex-col min-w-0 justify-center">
                    <h4 className="text-[12px] font-medium text-white line-clamp-2 leading-tight group-hover:text-[#3EA6FF]">
                      {rel.title.includes('•') ? rel.title.split('•').slice(1).join('•').trim() : rel.title}
                    </h4>
                    <span className="text-[11px] text-[#888888] mt-1 truncate">
                      {rel.channel_name || 'KidsTube'}
                    </span>
                  </div>
                </div>
              ))}
          </div>
        </div>
      </div>
    </div>
  );
};

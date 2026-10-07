import React, { useState, useEffect, useRef } from 'react';
import type { Video, ChildProfile } from '../types/video';
import { 
  getStreamUrl, 
  getChannelIconUrl, 
  getYoutubeId, 
  getYoutubeEmbedUrl, 
  isSelfHosted 
} from '../lib/constants';
import { 
  Play, 
  Pause, 
  Volume2, 
  VolumeX, 
  Maximize, 
  RotateCcw, 
  Heart, 
  Tv, 
  Layers, 
  ExternalLink 
} from 'lucide-react';
import { KidsTopBar } from './KidsTopBar';
import { KidsSidebar } from './KidsSidebar';

interface WatchPageProps {
  video: Video;
  relatedVideos: Video[];
  profiles: ChildProfile[];
}

export const WatchPage: React.FC<WatchPageProps> = ({
  video,
  relatedVideos = [],
  profiles = [],
}) => {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const [isPlaying, setIsPlaying] = useState(true);
  const [isMuted, setIsMuted] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(video.duration || 0);
  const [isTheater, setIsTheater] = useState(false);
  const [forceEmbed, setForceEmbed] = useState(false);
  const [streamError, setStreamError] = useState(false);
  const [hasRecordedView, setHasRecordedView] = useState(false);

  // Reusable Sidebar state
  const [isSidebarExpanded, setIsSidebarExpanded] = useState(false);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const [isFavorite, setIsFavorite] = useState<boolean>(() => {
    if (typeof window !== 'undefined') {
      try {
        const stored = localStorage.getItem('kidstube_favorites');
        if (stored) {
          const set = new Set(JSON.parse(stored));
          return set.has(video.id);
        }
      } catch {
        // fallback
      }
    }
    return false;
  });

  const youtubeId = getYoutubeId(video);
  const selfHostedAvailable = isSelfHosted(video) && !streamError && !forceEmbed;
  const streamUrl = getStreamUrl(video);
  const avatarUrl = getChannelIconUrl(video);
  const embedUrl = getYoutubeEmbedUrl(youtubeId, true);

  const cleanChannelName = video.channel_name || (video.title.includes('•') ? video.title.split('•')[0].trim() : 'KidsTube');
  const cleanTitle = video.title.includes('•') ? video.title.split('•').slice(1).join('•').trim() : video.title;

  // Record watch view after 5s
  useEffect(() => {
    if (hasRecordedView) return;
    const timer = setTimeout(() => {
      fetch('/api/metrics/watch', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ video_id: video.id, seconds_watched: 10 }),
      }).catch(() => null);
      setHasRecordedView(true);
    }, 5000);

    return () => clearTimeout(timer);
  }, [video.id, hasRecordedView]);

  // Handle keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === ' ' && videoRef.current) {
        e.preventDefault();
        togglePlay();
      }
      if (e.key === 'f' || e.key === 'F') {
        toggleFullscreen();
      }
      if (e.key === 't' || e.key === 'T') {
        setIsTheater((prev) => !prev);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

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
    const el = document.getElementById('player-container');
    if (!el) return;
    if (document.fullscreenElement) {
      document.exitFullscreen();
    } else {
      el.requestFullscreen();
    }
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const targetTime = Number(e.target.value);
    if (videoRef.current) {
      videoRef.current.currentTime = targetTime;
      setCurrentTime(targetTime);
    }
  };

  const toggleFavorite = () => {
    setIsFavorite((prev) => {
      const next = !prev;
      try {
        const stored = localStorage.getItem('kidstube_favorites');
        const set = stored ? new Set(JSON.parse(stored)) : new Set();
        if (next) set.add(video.id);
        else set.delete(video.id);
        localStorage.setItem('kidstube_favorites', JSON.stringify(Array.from(set)));
      } catch {
        // ignore
      }
      return next;
    });
  };

  const formatSeconds = (sec: number) => {
    const m = Math.floor(sec / 60);
    const s = Math.floor(sec % 60);
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  };

  return (
    <div className="min-h-screen bg-[#0F0F0F] text-[#F1F1F1] flex flex-col font-sans">
      {/* 1. Reusable Authentic YouTube Kids Top Bar */}
      <KidsTopBar
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        onToggleSidebar={() => {
          if (window.innerWidth < 1024) {
            setIsMobileSidebarOpen((prev) => !prev);
          } else {
            setIsSidebarExpanded((prev) => !prev);
          }
        }}
        badgeText="Watch"
      />

      {/* 2. Main Flex Layout: Sidebar + Watch Content */}
      <div className="flex flex-1 relative overflow-x-hidden">
        {/* Reusable YouTube Sidebar */}
        <KidsSidebar
          isExpanded={isSidebarExpanded}
          isMobileOpen={isMobileSidebarOpen}
          onCloseMobile={() => setIsMobileSidebarOpen(false)}
          activeNav="watch"
        />

        {/* 3. Watch Layout Container (Player + Details + Up Next Sidebar) */}
        <main className={`flex-1 min-w-0 p-3 sm:p-5 md:p-6 transition-all duration-200 ${isTheater ? 'max-w-none' : 'max-w-7xl mx-auto'}`}>
          <div className="flex flex-col lg:flex-row gap-6">
            
            {/* Primary Column: Video Player & Details */}
            <div className="flex-1 min-w-0">
              {/* Player Container */}
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

              {/* Video Details & Actions */}
              <div className="mt-4 pb-6 border-b border-[#222222]">
                <h1 className="text-[18px] sm:text-[21px] font-bold leading-snug text-white">
                  {cleanTitle}
                </h1>

                <div className="mt-3 flex flex-wrap items-center justify-between gap-4">
                  {/* Channel Avatar & Info */}
                  <div className="flex items-center gap-3">
                    {avatarUrl ? (
                      <img
                        src={avatarUrl}
                        alt={cleanChannelName}
                        className="w-10 h-10 rounded-full object-cover bg-[#222222] border border-[#333333]"
                      />
                    ) : (
                      <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-rose-600 to-amber-500 flex items-center justify-center text-white font-bold text-[14px]">
                        {cleanChannelName.charAt(0).toUpperCase()}
                      </div>
                    )}

                    <div className="flex flex-col">
                      <span className="font-semibold text-white text-[15px] leading-tight">
                        {cleanChannelName}
                      </span>
                      <span className="text-[12px] text-[#888888] capitalize">
                        {video.category_id} • Safe Kids Content
                      </span>
                    </div>
                  </div>

                  {/* Actions & Badges */}
                  <div className="flex items-center gap-2.5">
                    {/* Favorite Button */}
                    <button
                      onClick={toggleFavorite}
                      className={`flex items-center gap-2 px-4 py-2 rounded-full text-[13px] font-medium border transition-colors cursor-pointer ${
                        isFavorite
                          ? 'bg-[#FF0000] text-white border-[#FF0000]'
                          : 'bg-[#222222] hover:bg-[#2c2c2c] text-[#F1F1F1] border-[#333333]'
                      }`}
                    >
                      <Heart className={`w-4 h-4 ${isFavorite ? 'fill-current' : ''}`} />
                      <span>{isFavorite ? 'Favorited' : 'Favorite'}</span>
                    </button>

                    {/* Mode Switcher */}
                    <button
                      onClick={() => setForceEmbed((prev) => !prev)}
                      className="px-3.5 py-2 bg-[#1A1A1A] hover:bg-[#252525] text-[#AAAAAA] hover:text-white rounded-full text-[12px] border border-[#2D2D2D] transition-colors cursor-pointer"
                      title="Toggle between self-hosted MP4 and YouTube player"
                    >
                      {selfHostedAvailable ? 'Switch to Embed' : 'Try Direct MP4'}
                    </button>

                    {/* Stream Status Badge */}
                    <span className="px-3 py-1.5 rounded-full bg-[#161616] border border-[#262626] text-[11px] font-mono text-[#888888] hidden sm:inline">
                      {selfHostedAvailable ? '⚡ MP4 Fast Stream' : '📺 YouTube Stream'}
                    </span>
                  </div>
                </div>

                {/* Video Description Box */}
                <div className="mt-4 p-4 rounded-2xl bg-[#1C1C1C] border border-[#2A2A2A] text-[13px] text-[#CCCCCC] leading-relaxed">
                  <div className="flex items-center gap-3 font-semibold text-white mb-2">
                    <span>{video.views || 0} safe views</span>
                    <span>•</span>
                    <span>Category: {video.category_id}</span>
                  </div>
                  <p className="line-clamp-3">
                    Curated for young children. 100% ad-free, secure, and monitored by parental controls.
                  </p>
                </div>
              </div>
            </div>

            {/* Secondary Column: "Up Next" Safe Queue */}
            <div className="w-full lg:w-96 shrink-0">
              <h2 className="text-[16px] font-bold text-white mb-3">Up Next</h2>

              <div className="flex flex-col gap-3">
                {relatedVideos.slice(0, 15).map((rel) => {
                  const relCleanTitle = rel.title.includes('•') ? rel.title.split('•').slice(1).join('•').trim() : rel.title;
                  const relChannel = rel.channel_name || (rel.title.includes('•') ? rel.title.split('•')[0].trim() : 'KidsTube');
                  const thumb = rel.thumbnail_url || `https://img.youtube.com/vi/${getYoutubeId(rel)}/mqdefault.jpg`;

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

          </div>
        </main>
      </div>
    </div>
  );
};

import React, { useState, useEffect, useRef } from 'react';
import type { Video, ChildProfile } from '@/types/video';
import {
  getStreamUrl,
  getChannelIconUrl,
  getYoutubeId,
  getYoutubeEmbedUrl,
  isSelfHosted
} from '@/lib/constants';
import { KidsTopBar } from './KidsTopBar';
import { KidsSidebar } from './KidsSidebar';
import { WatchPlayer } from '@/features/player/components/WatchPlayer';
import { WatchDetails } from '@/features/player/components/WatchDetails';
import { WatchUpNextSidebar } from '@/features/player/components/WatchUpNextSidebar';

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
    <div className="min-h-screen bg-canvas text-text-primary flex flex-col font-sans">
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

      <div className="flex flex-1 relative overflow-x-clip">
        <KidsSidebar
          isExpanded={isSidebarExpanded}
          isMobileOpen={isMobileSidebarOpen}
          onCloseMobile={() => setIsMobileSidebarOpen(false)}
          activeNav="watch"
        />

        <main className={`flex-1 min-w-0 p-3 sm:p-5 md:p-6 transition-all duration-200 ${isTheater ? 'max-w-none' : 'max-w-[1920px] mx-auto'}`}>
          <div className="flex flex-col lg:flex-row gap-6 items-start">
            {/* Left Column: Sticky Video Player & Details */}
            <div className="flex-1 min-w-0 w-full lg:sticky lg:top-20 lg:self-start z-20 lg:max-h-[calc(100vh-5.5rem)] lg:overflow-y-auto custom-scrollbar">
              {/* Mobile sticky wrapper for player */}
              <div className="sticky top-16 z-30 bg-canvas -mx-3 sm:-mx-5 md:-mx-6 px-3 sm:px-5 md:px-6 pt-1 pb-2 lg:static lg:bg-transparent lg:p-0 lg:m-0">
                <WatchPlayer
                  video={video}
                  selfHostedAvailable={selfHostedAvailable}
                  streamUrl={streamUrl}
                  embedUrl={embedUrl}
                  isPlaying={isPlaying}
                  isMuted={isMuted}
                  currentTime={currentTime}
                  duration={duration}
                  isTheater={isTheater}
                  setIsTheater={setIsTheater}
                  setStreamError={setStreamError}
                  setCurrentTime={setCurrentTime}
                  setDuration={setDuration}
                  setIsPlaying={setIsPlaying}
                  videoRef={videoRef}
                  togglePlay={togglePlay}
                  toggleMute={toggleMute}
                  toggleFullscreen={toggleFullscreen}
                  handleSeek={handleSeek}
                  formatSeconds={formatSeconds}
                />
              </div>

              <WatchDetails
                video={video}
                cleanTitle={cleanTitle}
                cleanChannelName={cleanChannelName}
                avatarUrl={avatarUrl}
                isFavorite={isFavorite}
                toggleFavorite={toggleFavorite}
                selfHostedAvailable={selfHostedAvailable}
                setForceEmbed={setForceEmbed}
              />
            </div>

            {/* Right Column: Up Next Playlist */}
            <WatchUpNextSidebar relatedVideos={relatedVideos} />
          </div>
        </main>
      </div>
    </div>
  );
};

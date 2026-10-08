import React, { useState, useEffect, useRef, useMemo } from 'react';
import type { Video, ChildProfile } from '@/types/video';
import { getYoutubeId, getYoutubeEmbedUrl, isSelfHosted } from '@/lib/constants';
import { KidsTopBar } from './KidsTopBar';
import { KidsSidebar } from './KidsSidebar';
import { ShortsReel } from '@/features/player/components/ShortsReel';
import { ShortsActionPills } from '@/features/player/components/ShortsActionPills';

interface ShortsPageProps {
  shorts: Video[];
  initialIndex?: number;
  profiles?: ChildProfile[];
}

export const ShortsPage: React.FC<ShortsPageProps> = ({
  shorts = [],
  initialIndex = 0,
  profiles = [],
}) => {
  const [currentIndex, setCurrentIndex] = useState(
    initialIndex >= 0 && initialIndex < shorts.length ? initialIndex : 0
  );

  const [isLiked, setIsLiked] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const [isSidebarExpanded, setIsSidebarExpanded] = useState(false);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [tapToNextEnabled, setTapToNextEnabled] = useState(true);
  const [advanceFeedback, setAdvanceFeedback] = useState(false);

  // Position & Scrubber state
  const [currentTime, setCurrentTime] = useState<number>(0);
  const [duration, setDuration] = useState<number>(60);
  const [isScrubbing, setIsScrubbing] = useState<boolean>(false);

  // Search state
  const [searchQuery, setSearchQuery] = useState('');

  // Refs for touch & gesture tracking
  const touchStartY = useRef<number | null>(null);
  const touchStartX = useRef<number | null>(null);
  const touchStartTime = useRef<number>(0);
  const lastScrollTime = useRef<number>(0);
  const lastAdvanceTime = useRef<number>(0);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const iframeRef = useRef<HTMLIFrameElement | null>(null);

  const currentShort = shorts[currentIndex];

  // Extract unique channels
  const channels = useMemo(() => {
    const set = new Set<string>();
    shorts.forEach((s) => {
      if (s.channel_name) set.add(s.channel_name);
    });
    return Array.from(set).slice(0, 8);
  }, [shorts]);

  // Reset position & like state when changing short
  useEffect(() => {
    setCurrentTime(0);
    setIsLiked(false);
    if (currentShort && currentShort.duration) {
      setDuration(currentShort.duration);
    } else {
      setDuration(60);
    }
  }, [currentIndex, currentShort]);

  // Simulated progress timer for YouTube Embeds so scrubber stays alive
  useEffect(() => {
    if (isSelfHosted(currentShort) || isScrubbing) return;

    const interval = setInterval(() => {
      setCurrentTime((prev) => {
        if (prev >= duration) {
          return 0; // Loop short
        }
        return prev + 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [currentIndex, duration, isScrubbing, currentShort]);

  const triggerAdvanceFeedback = () => {
    setAdvanceFeedback(true);
    setTimeout(() => setAdvanceFeedback(false), 380);
  };

  const handleNext = () => {
    const now = Date.now();
    if (now - lastAdvanceTime.current < 320) return; // Debounce rapid multiple taps
    lastAdvanceTime.current = now;

    if (currentIndex < shorts.length - 1) {
      setCurrentIndex((prev) => prev + 1);
      triggerAdvanceFeedback();
    } else {
      setCurrentIndex(0);
      triggerAdvanceFeedback();
    }
  };

  const handlePrev = () => {
    const now = Date.now();
    if (now - lastAdvanceTime.current < 320) return;
    lastAdvanceTime.current = now;

    if (currentIndex > 0) {
      setCurrentIndex((prev) => prev - 1);
      triggerAdvanceFeedback();
    }
  };

  // Keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowDown' || e.key === 'PageDown' || e.key === 'j') {
        e.preventDefault();
        handleNext();
      } else if (e.key === 'ArrowUp' || e.key === 'PageUp' || e.key === 'k') {
        e.preventDefault();
        handlePrev();
      } else if (e.key === 'm' || e.key === 'M') {
        setIsMuted((prev) => !prev);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [currentIndex, shorts.length]);

  // Trackpad / Mouse wheel scroll handler
  const handleWheel = (e: React.WheelEvent) => {
    const now = Date.now();
    if (now - lastScrollTime.current < 650) return; // Debounce 650ms

    if (e.deltaY > 40) {
      lastScrollTime.current = now;
      handleNext();
    } else if (e.deltaY < -40) {
      lastScrollTime.current = now;
      handlePrev();
    }
  };

  // Tablet & Touch Drive Gesture Handlers
  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartY.current = e.touches[0].clientY;
    touchStartX.current = e.touches[0].clientX;
    touchStartTime.current = Date.now();
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    if (touchStartY.current === null) return;
    const deltaY = e.changedTouches[0].clientY - touchStartY.current;
    const deltaX = (touchStartX.current !== null) ? e.changedTouches[0].clientX - touchStartX.current : 0;
    const touchDuration = Date.now() - touchStartTime.current;

    if (Math.abs(deltaY) > Math.abs(deltaX) && Math.abs(deltaY) > 40) {
      if (deltaY < -40) {
        handleNext(); // Swiped UP -> Next Short
      } else if (deltaY > 40) {
        handlePrev(); // Swiped DOWN -> Previous Short
      }
    } else if (Math.abs(deltaY) < 25 && Math.abs(deltaX) < 25 && touchDuration < 450) {
      if (tapToNextEnabled) {
        handleNext(); // Clean TAP on tablet -> Move to Next Short
      }
    }

    touchStartY.current = null;
    touchStartX.current = null;
  };

  const handleScreenTap = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (tapToNextEnabled) {
      handleNext();
    }
  };

  const handleScrubberChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newTime = Number(e.target.value);
    setCurrentTime(newTime);
    if (videoRef.current) {
      videoRef.current.currentTime = newTime;
    } else if (iframeRef.current && iframeRef.current.contentWindow) {
      iframeRef.current.contentWindow.postMessage(
        JSON.stringify({ event: 'command', func: 'seekTo', args: [newTime, true] }),
        'https://www.youtube-nocookie.com'
      );
    }
  };

  const formatSeconds = (sec: number) => {
    const m = Math.floor(sec / 60);
    const s = Math.floor(sec % 60);
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  };

  if (!currentShort) {
    return (
      <div className="min-h-screen bg-canvas-deep text-text-primary flex flex-col items-center justify-center p-4">
        <p className="text-[15px] text-text-secondary">No Shorts available in the catalog.</p>
        <a href="/" className="mt-4 px-4 py-2 bg-surface rounded-xl text-[13px] text-text-primary hover:bg-surface-elevated border border-border transition-colors">
          Back to Home
        </a>
      </div>
    );
  }

  const youtubeId = getYoutubeId(currentShort);
  const selfHosted = isSelfHosted(currentShort);
  const embedUrl = `${getYoutubeEmbedUrl(youtubeId, true)}&enablejsapi=1`;

  return (
    <div className="h-screen w-screen bg-canvas-deep text-text-primary flex flex-col overflow-hidden font-sans select-none">
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
        badgeText="Shorts"
        tapToNextEnabled={tapToNextEnabled}
        onToggleTapToNext={() => setTapToNextEnabled((prev) => !prev)}
        profiles={profiles}
      />

      <div className="flex-1 flex overflow-hidden">
        <KidsSidebar
          isExpanded={isSidebarExpanded}
          isMobileOpen={isMobileSidebarOpen}
          onCloseMobile={() => setIsMobileSidebarOpen(false)}
          activeNav="shorts"
          channels={channels}
        />

        <main
          onWheel={handleWheel}
          className="flex-1 flex items-center justify-center p-2 sm:p-4 md:p-6 overflow-hidden relative"
        >
          <div className="relative flex items-center gap-3 sm:gap-6 max-h-[86vh] h-full">
            <ShortsReel
              currentShort={currentShort}
              selfHosted={selfHosted}
              videoRef={videoRef}
              iframeRef={iframeRef}
              embedUrl={embedUrl}
              isMuted={isMuted}
              isScrubbing={isScrubbing}
              setIsScrubbing={setIsScrubbing}
              currentTime={currentTime}
              setCurrentTime={setCurrentTime}
              duration={duration}
              setDuration={setDuration}
              handleTouchStart={handleTouchStart}
              handleTouchEnd={handleTouchEnd}
              handleScreenTap={handleScreenTap}
              handleScrubberChange={handleScrubberChange}
              tapToNextEnabled={tapToNextEnabled}
              advanceFeedback={advanceFeedback}
              formatSeconds={formatSeconds}
            />

            <ShortsActionPills
              currentIndex={currentIndex}
              totalCount={shorts.length}
              isLiked={isLiked}
              isMuted={isMuted}
              handlePrev={handlePrev}
              handleNext={handleNext}
              setIsLiked={setIsLiked}
              setIsMuted={setIsMuted}
            />
          </div>
        </main>
      </div>
    </div>
  );
};

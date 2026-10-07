import React, { useState, useEffect, useRef, useMemo } from 'react';
import type { Video, ChildProfile } from '../types/video';
import { 
  ChevronUp, 
  ChevronDown, 
  Heart, 
  Volume2, 
  VolumeX, 
  ArrowRight
} from 'lucide-react';
import { getYoutubeId, getYoutubeEmbedUrl, isSelfHosted, getStreamUrl } from '../lib/constants';
import { KidsTopBar } from './KidsTopBar';
import { KidsSidebar } from './KidsSidebar';

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
        '*'
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
      <div className="min-h-screen bg-[#0F0F0F] text-white flex flex-col items-center justify-center p-4">
        <p className="text-[15px] text-[#888888]">No Shorts available in the catalog.</p>
        <a href="/" className="mt-4 px-4 py-2 bg-[#222222] rounded-xl text-[13px] text-white hover:bg-[#333333]">
          Back to Home
        </a>
      </div>
    );
  }

  const youtubeId = getYoutubeId(currentShort);
  const selfHosted = isSelfHosted(currentShort);
  const embedUrl = `${getYoutubeEmbedUrl(youtubeId, true)}&enablejsapi=1`;

  return (
    <div className="h-screen w-screen bg-[#0F0F0F] text-[#F1F1F1] flex flex-col overflow-hidden font-sans select-none">
      
      {/* 1. Reusable Authentic YouTube Top Bar */}
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

      {/* 2. Middle Body: Reusable Sidebar + Shorts Feed */}
      <div className="flex-1 flex overflow-hidden">
        {/* Reusable YouTube Sidebar */}
        <KidsSidebar
          isExpanded={isSidebarExpanded}
          isMobileOpen={isMobileSidebarOpen}
          onCloseMobile={() => setIsMobileSidebarOpen(false)}
          activeNav="shorts"
          channels={channels}
        />

        {/* 3. Main Shorts Reel with Tablet Touch Drive & Kid-Safe Overlay Shields */}
        <main
          onWheel={handleWheel}
          className="flex-1 flex items-center justify-center p-2 sm:p-4 md:p-6 overflow-hidden relative"
        >
          {/* Shorts Container */}
          <div className="relative flex items-center gap-3 sm:gap-6 max-h-[86vh] h-full">
            
            {/* The 9:16 Video Box */}
            <div 
              onTouchStart={handleTouchStart}
              onTouchEnd={handleTouchEnd}
              className="relative h-full aspect-[9/16] rounded-3xl overflow-hidden bg-black shadow-2xl border border-[#282828] flex items-center justify-center select-none"
            >
              {selfHosted ? (
                // MODE A: Native Self-Hosted MP4 Player
                <video
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
                // MODE B: YouTube Embed with Transparent Shields
                <>
                  <iframe
                    ref={iframeRef}
                    src={embedUrl}
                    title={currentShort.title}
                    className="w-full h-full border-0 pointer-events-auto"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                    allowFullScreen
                  />

                  {/* SHIELD 1: Top Blocker (Blocks title, channel avatar & share button) */}
                  <div 
                    onClick={handleScreenTap}
                    className="absolute top-0 inset-x-0 h-18 z-30 bg-transparent cursor-pointer"
                    title="Kid Safe Shield: Top External Links Blocked"
                  />

                  {/* SHIELD 2: Bottom-Right Blocker (Blocks YouTube logo & settings gear) */}
                  <div 
                    onClick={handleScreenTap}
                    className="absolute bottom-0 right-0 w-36 h-14 z-30 bg-transparent cursor-pointer"
                    title="Kid Safe Shield: YouTube Logo & Settings Blocked"
                  />

                  {/* SHIELD 3: Center Touch-to-Next Advance Zone */}
                  {tapToNextEnabled && (
                    <div
                      onClick={handleScreenTap}
                      className="absolute inset-x-0 top-18 bottom-14 z-20 bg-transparent cursor-pointer flex items-center justify-center"
                    />
                  )}
                </>
              )}

              {/* Animated Kid Touch Visual Feedback */}
              {advanceFeedback && (
                <div className="absolute inset-0 z-40 flex items-center justify-center pointer-events-none">
                  <div className="px-5 py-3 rounded-2xl bg-black/75 backdrop-blur-md border border-white/20 text-white flex items-center gap-2.5 shadow-2xl animate-bounce">
                    <span className="text-[14px] font-bold tracking-wide">Next Video</span>
                    <ArrowRight className="w-5 h-5 text-[#FF0000]" />
                  </div>
                </div>
              )}

              {/* Video Title & Channel Metadata Overlay */}
              <div className="absolute inset-x-0 bottom-8 p-4 bg-gradient-to-t from-black/95 via-black/50 to-transparent pointer-events-none z-20">
                <h2 className="text-[14px] sm:text-[15px] font-semibold text-white drop-shadow-md line-clamp-2">
                  {currentShort.title}
                </h2>
                <div className="flex items-center gap-2 mt-2">
                  <span className="text-[12px] text-[#DDDDDD] font-medium opacity-90 truncate">
                    {currentShort.channel_name || 'KidsTube Short'}
                  </span>
                  <span className="px-1.5 py-0.5 rounded bg-emerald-950 text-emerald-400 text-[10px] font-bold border border-emerald-800">
                    Safe
                  </span>
                  {tapToNextEnabled && (
                    <span className="text-[10px] text-amber-300 font-medium">
                      • Touch screen for next
                    </span>
                  )}
                </div>
              </div>

              {/* Kid-Safe Position / Progress Slider */}
              <div 
                onClick={(e) => e.stopPropagation()}
                onTouchStart={(e) => e.stopPropagation()}
                onTouchEnd={(e) => e.stopPropagation()}
                className="absolute inset-x-0 bottom-0 z-35 px-4 pb-2 pt-4 bg-gradient-to-t from-black/90 to-transparent flex flex-col gap-1 select-none"
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
                    className="w-full h-1 sm:h-1.5 bg-[#444444] accent-[#FF0000] hover:h-2 transition-all rounded-lg appearance-none cursor-pointer"
                    title="Position Progress Slider"
                  />
                </div>
                <div className="flex items-center justify-between text-[10px] font-mono text-[#AAAAAA] px-0.5">
                  <span>{formatSeconds(currentTime)}</span>
                  <span>{formatSeconds(duration)}</span>
                </div>
              </div>
            </div>

            {/* Right Action Pills */}
            <div className="flex flex-col items-center gap-3 z-30">
              <button
                onClick={handlePrev}
                disabled={currentIndex === 0}
                className="w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-[#1F1F1F] hover:bg-[#2C2C2C] disabled:opacity-25 disabled:pointer-events-none flex items-center justify-center text-white border border-[#333333] transition-all cursor-pointer shadow-xl active:scale-90"
                title="Previous Short"
              >
                <ChevronUp className="w-6 h-6" />
              </button>

              <button
                onClick={() => setIsLiked((prev) => !prev)}
                className={`w-11 h-11 sm:w-12 sm:h-12 rounded-full flex flex-col items-center justify-center border transition-all cursor-pointer shadow-xl active:scale-90 ${
                  isLiked
                    ? 'bg-[#FF0000] text-white border-[#FF0000]'
                    : 'bg-[#1F1F1F] hover:bg-[#2C2C2C] text-white border-[#333333]'
                }`}
                title="Favorite this short"
              >
                <Heart className={`w-5 h-5 ${isLiked ? 'fill-current' : ''}`} />
              </button>

              <button
                onClick={() => setIsMuted((prev) => !prev)}
                className="w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-[#1F1F1F] hover:bg-[#2C2C2C] flex items-center justify-center text-white border border-[#333333] transition-all cursor-pointer shadow-xl active:scale-90"
                title={isMuted ? 'Unmute' : 'Mute'}
              >
                {isMuted ? <VolumeX className="w-5 h-5 text-[#FF0000]" /> : <Volume2 className="w-5 h-5" />}
              </button>

              <button
                onClick={handleNext}
                disabled={currentIndex === shorts.length - 1}
                className="w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-[#1F1F1F] hover:bg-[#2C2C2C] disabled:opacity-25 disabled:pointer-events-none flex items-center justify-center text-white border border-[#333333] transition-all cursor-pointer shadow-xl active:scale-90"
                title="Next Short"
              >
                <ChevronDown className="w-6 h-6" />
              </button>

              <div className="mt-1 px-2.5 py-1 rounded-full bg-[#181818] border border-[#2D2D2D] text-[11px] font-mono text-[#AAAAAA] text-center">
                {currentIndex + 1}/{shorts.length}
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

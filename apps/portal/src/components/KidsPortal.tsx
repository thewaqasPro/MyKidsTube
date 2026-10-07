import React, { useState, useMemo } from 'react';
import type { Video, Category, ChildProfile } from '../types/video';
import { KidsTopBar } from './KidsTopBar';
import { KidsSidebar } from './KidsSidebar';
import { CategoryPills } from './CategoryPills';
import { ShortsShelf } from './ShortsShelf';
import { VideoGrid } from './VideoGrid';
import { MEDIA_BASE, isVideoShort } from '../lib/constants';

interface KidsPortalProps {
  initialVideos: Video[];
  initialCategories: Category[];
  initialProfiles: ChildProfile[];
}

export const KidsPortal: React.FC<KidsPortalProps> = ({
  initialVideos,
  initialCategories,
  initialProfiles,
}) => {
  const [videos, setVideos] = useState<Video[]>(initialVideos);
  const [categories, setCategories] = useState<Category[]>(initialCategories);
  const [profiles, setProfiles] = useState<ChildProfile[]>(initialProfiles);
  const [selectedProfileId, setSelectedProfileId] = useState<string>(
    initialProfiles[0]?.id || 'kids_all'
  );

  const [selectedCategoryId, setSelectedCategoryId] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Sidebar navigation state
  const [isSidebarExpanded, setIsSidebarExpanded] = useState<boolean>(true);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState<boolean>(false);
  const [activeNav, setActiveNav] = useState<string>('home'); // 'home' | 'shorts' | 'favorites' | 'channel:...'

  // Favorites state persisted in localStorage
  const [favorites, setFavorites] = useState<Set<string>>(() => {
    if (typeof window !== 'undefined') {
      try {
        const stored = localStorage.getItem('kidstube_favorites');
        if (stored) return new Set(JSON.parse(stored));
      } catch {
        // fallback
      }
    }
    return new Set<string>();
  });



  // Extract distinct channels from videos
  const channels = useMemo<ChannelItem[]>(() => {
    const map = new Map<string, { name: string; icon?: string; count: number }>();
    videos.forEach((v) => {
      const chName = v.channel_name || (v.title.includes('•') ? v.title.split('•')[0].trim() : '');
      if (!chName) return;
      
      const iconUrl = v.channel_icon_url || (v.channel_icon ? (v.channel_icon.startsWith('http') ? v.channel_icon : `${MEDIA_BASE}/thumbs/${v.channel_icon}`) : undefined);
      
      const existing = map.get(chName);
      if (existing) {
        existing.count += 1;
        if (!existing.icon && iconUrl) existing.icon = iconUrl;
      } else {
        map.set(chName, {
          name: chName,
          icon: iconUrl,
          count: 1,
        });
      }
    });

    return Array.from(map.values()).sort((a, b) => b.count - a.count);
  }, [videos]);

  // Split into normal videos and shorts according to video length
  const shortsList = useMemo(() => {
    return videos.filter(isVideoShort);
  }, [videos]);

  const regularVideos = useMemo(() => {
    return videos.filter((v) => !isVideoShort(v));
  }, [videos]);

  const toggleFavorite = (videoId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setFavorites((prev) => {
      const next = new Set(prev);
      if (next.has(videoId)) {
        next.delete(videoId);
      } else {
        next.add(videoId);
      }
      try {
        localStorage.setItem('kidstube_favorites', JSON.stringify(Array.from(next)));
      } catch {
        // ignore
      }
      return next;
    });
  };

  const handleToggleSidebar = () => {
    if (typeof window !== 'undefined' && window.innerWidth < 1024) {
      setIsMobileSidebarOpen((prev) => !prev);
    } else {
      setIsSidebarExpanded((prev) => !prev);
    }
  };

  const handleSelectNav = (navId: string) => {
    setActiveNav(navId);
    if (navId === 'home') {
      setSelectedCategoryId('all');
    }
  };

  // Filtered lists based on sidebar nav, search & active category
  const displayVideos = useMemo(() => {
    let list: Video[] = [];

    if (activeNav === 'favorites') {
      list = videos.filter((v) => favorites.has(v.id));
    } else if (activeNav === 'shorts') {
      list = shortsList;
    } else if (activeNav.startsWith('channel:')) {
      const chName = activeNav.replace('channel:', '');
      list = videos.filter((v) => {
        const itemChannel = v.channel_name || (v.title.includes('•') ? v.title.split('•')[0].trim() : '');
        return itemChannel === chName;
      });
    } else {
      // 'home'
      list = selectedCategoryId === 'all'
        ? regularVideos
        : selectedCategoryId === 'shorts'
        ? []
        : regularVideos.filter((v) => v.category_id === selectedCategoryId);
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      list = list.filter(
        (v) =>
          v.title.toLowerCase().includes(q) ||
          v.channel_name.toLowerCase().includes(q)
      );
    }

    return list;
  }, [videos, regularVideos, shortsList, activeNav, selectedCategoryId, searchQuery, favorites]);

  const filteredShorts = useMemo(() => {
    if (activeNav !== 'home') return [];
    if (selectedCategoryId !== 'all' && selectedCategoryId !== 'shorts') {
      return [];
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      return shortsList.filter(
        (s) =>
          s.title.toLowerCase().includes(q) ||
          s.channel_name.toLowerCase().includes(q)
      );
    }
    return shortsList;
  }, [shortsList, activeNav, selectedCategoryId, searchQuery]);

  const gridTitle = useMemo(() => {
    if (activeNav === 'favorites') return `Favorites (${favorites.size})`;
    if (activeNav === 'shorts') return 'All Shorts & Reels';
    if (activeNav.startsWith('channel:')) return activeNav.replace('channel:', '');
    if (selectedCategoryId === 'all') return 'Recommended Safe Content';
    return categories.find((c) => c.id === selectedCategoryId)?.name || 'Videos';
  }, [activeNav, favorites.size, selectedCategoryId, categories]);

  const handlePlayShort = (short: Video) => {
    window.location.href = `/shorts?v=${short.id}`;
  };

  const handlePlayVideoOrShort = (video: Video) => {
    if (isVideoShort(video)) {
      handlePlayShort(video);
    } else {
      window.location.href = `/watch/${video.id}`;
    }
  };

  const handleRefreshCatalog = async () => {
    try {
      const res = await fetch('/api/catalog');
      if (res.ok) {
        const data = await res.json();
        if (data.all_videos && Array.isArray(data.all_videos)) {
          setVideos(data.all_videos);
        }
        if (data.categories && Array.isArray(data.categories)) {
          setCategories(data.categories);
        }
        if (data.profiles && Array.isArray(data.profiles)) {
          setProfiles(data.profiles);
        }
      }
    } catch {
      // ignore
    }
  };

  return (
    <div className="min-h-screen bg-[#0F0F0F] text-[#F1F1F1] flex flex-col font-sans selection:bg-[#FF0000] selection:text-white">
      {/* Top YouTube Header */}
      <KidsTopBar
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        profiles={profiles}
        selectedProfileId={selectedProfileId}
        onProfileSelect={setSelectedProfileId}
        onToggleSidebar={handleToggleSidebar}
        badgeText="Safe"
      />

      {/* Main Layout Area with Reusable YouTube Sidebar */}
      <div className="flex flex-1 relative overflow-x-hidden">
        {/* Left Sidebar */}
        <KidsSidebar
          isExpanded={isSidebarExpanded}
          isMobileOpen={isMobileSidebarOpen}
          onCloseMobile={() => setIsMobileSidebarOpen(false)}
          activeNav={activeNav}
          onSelectNav={handleSelectNav}
          channels={channels}
        />

        {/* Content Body */}
        <div className="flex-1 flex flex-col min-w-0">
          {/* Horizontal Category Filter Pills (Shown on Home view) */}
          {activeNav === 'home' && (
            <CategoryPills
              categories={categories}
              selectedCategoryId={selectedCategoryId}
              onSelectCategory={setSelectedCategoryId}
            />
          )}

          {/* Active Filter Pill indicator if in a channel or favorites */}
          {activeNav !== 'home' && (
            <div className="px-4 sm:px-6 pt-4 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-[13px] text-[#AAAAAA]">Viewing:</span>
                <span className="px-3 py-1 rounded-full bg-[#272727] text-white text-[13px] font-semibold flex items-center gap-2">
                  {gridTitle}
                  <button
                    onClick={() => handleSelectNav('home')}
                    className="hover:text-[#FF0000] text-[#AAAAAA] ml-1 text-[15px]"
                    title="Clear filter"
                  >
                    ×
                  </button>
                </span>
              </div>
            </div>
          )}

          {/* Main Videos Section */}
          <main className="flex-1 pb-16 max-w-[1920px] w-full mx-auto">
            {/* Shorts Shelf (Visible on 'Home' view when 'All' or 'Shorts' selected) */}
            {filteredShorts.length > 0 && (
              <ShortsShelf
                shorts={filteredShorts}
                onPlayShort={handlePlayShort}
              />
            )}

            {/* Video Grid */}
            <VideoGrid
              videos={displayVideos}
              onPlayVideo={handlePlayVideoOrShort}
              title={gridTitle}
              favorites={favorites}
              onToggleFavorite={toggleFavorite}
              emptyMessage={
                activeNav === 'favorites'
                  ? 'No favorite videos saved yet. Click the heart icon on any video card to save it here!'
                  : undefined
              }
            />
          </main>
        </div>
      </div>


    </div>
  );
};

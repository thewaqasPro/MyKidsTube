import React, { useState } from 'react';
import { Menu, Play, Search, Mic, Plus, Tv, Lock, X } from 'lucide-react';
import type { ChildProfile } from '../types/video';

export interface KidsTopBarProps {
  searchQuery?: string;
  onSearchChange?: (q: string) => void;
  onToggleSidebar?: () => void;
  badgeText?: string; // e.g. "Safe", "Shorts", "Kids"
  tapToNextEnabled?: boolean;
  onToggleTapToNext?: () => void;
  profiles?: ChildProfile[];
  selectedProfileId?: string;
  onProfileSelect?: (id: string) => void;
}

export const KidsTopBar: React.FC<KidsTopBarProps> = ({
  searchQuery = '',
  onSearchChange,
  onToggleSidebar,
  badgeText = 'Safe',
  tapToNextEnabled,
  onToggleTapToNext,
  profiles = [],
  selectedProfileId,
  onProfileSelect,
}) => {
  const [localQuery, setLocalQuery] = useState(searchQuery);

  const handleQueryChange = (val: string) => {
    setLocalQuery(val);
    if (onSearchChange) {
      onSearchChange(val);
    }
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (onSearchChange) {
      onSearchChange(localQuery);
    } else if (localQuery.trim()) {
      window.location.href = `/?q=${encodeURIComponent(localQuery.trim())}`;
    }
  };

  return (
    <header className="sticky top-0 z-50 flex items-center justify-between h-14 px-3 sm:px-6 bg-[#0F0F0F] border-b border-[#222222] select-none">
      {/* 1. Left: Hamburger Menu & Brand Logo */}
      <div className="flex items-center gap-2 sm:gap-3">
        {onToggleSidebar && (
          <button
            onClick={onToggleSidebar}
            aria-label="Toggle navigation sidebar"
            className="p-2 -ml-1 rounded-full text-[#AAAAAA] hover:text-white hover:bg-[#222222] transition-colors cursor-pointer"
            title="Toggle Sidebar"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}

        <a href="/" className="flex items-center gap-2 group select-none">
          <div className="flex items-center justify-center w-7 h-5 sm:w-8 sm:h-6 bg-[#FF0000] rounded-lg shadow-sm group-hover:scale-105 transition-transform">
            <Play className="w-3.5 h-3.5 text-white fill-current ml-0.5" />
          </div>
          <div className="flex items-center">
            <span className="text-[17px] sm:text-[18px] font-bold tracking-tight text-white font-sans">
              Kids<span className="text-[#FF0000]">Tube</span>
            </span>
            <span className="ml-1.5 px-1.5 py-0.2 text-[10px] font-bold uppercase tracking-wider bg-[#FF0000]/15 text-[#FF0000] rounded border border-[#FF0000]/30">
              {badgeText}
            </span>
          </div>
        </a>
      </div>

      {/* 2. Center: Authentic YouTube Search Bar + Voice Mic Button */}
      <div className="flex-1 max-w-xl mx-4 sm:mx-8 hidden sm:flex items-center justify-center">
        <form onSubmit={handleSearchSubmit} className="flex items-center w-full max-w-md">
          <div className="relative flex-1 flex items-center bg-[#121212] border border-[#303030] rounded-l-full focus-within:border-[#1C62B9] transition-colors">
            <input
              type="text"
              value={localQuery}
              onChange={(e) => handleQueryChange(e.target.value)}
              placeholder="Search safe kids videos & songs..."
              className="w-full h-9 pl-4 pr-8 bg-transparent text-[13px] text-white placeholder-[#717171] outline-none"
            />
            {localQuery && (
              <button
                type="button"
                onClick={() => handleQueryChange('')}
                className="absolute right-2.5 text-[#888888] hover:text-white p-1"
                title="Clear"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
          <button
            type="submit"
            className="h-9 px-5 flex items-center justify-center bg-[#222222] hover:bg-[#272727] border-y border-r border-[#303030] rounded-r-full text-[#AAAAAA] hover:text-white transition-colors cursor-pointer"
            title="Search"
          >
            <Search className="w-4 h-4" />
          </button>
        </form>

        <button
          type="button"
          className="ml-2.5 p-2.5 rounded-full bg-[#181818] hover:bg-[#272727] text-[#AAAAAA] hover:text-white transition-colors cursor-pointer shrink-0"
          title="Search with voice"
        >
          <Mic className="w-4 h-4" />
        </button>
      </div>

      {/* 3. Right: Action Buttons, Kid Lock & Avatar */}
      <div className="flex items-center gap-2 sm:gap-2.5">
        {/* Optional Touch-to-Next Kid Shield Switch */}
        {onToggleTapToNext && (
          <button
            onClick={onToggleTapToNext}
            className={`flex items-center gap-1.5 h-8.5 px-3 rounded-full text-[12px] font-medium border transition-colors cursor-pointer ${
              tapToNextEnabled
                ? 'bg-emerald-950/70 text-emerald-400 border-emerald-800'
                : 'bg-[#222222] text-[#888888] border-[#333333]'
            }`}
            title={tapToNextEnabled ? 'Touch-to-Next: ON (Touching screen advances video)' : 'Touch-to-Next: OFF'}
          >
            <Lock className="w-3.5 h-3.5" />
            <span className="hidden md:inline">
              {tapToNextEnabled ? 'Touch-to-Next: ON' : 'Touch-to-Next: OFF'}
            </span>
          </button>
        )}

        {/* Add Video / Wishlist */}
        <a
          href="/upload"
          className="flex items-center gap-1.5 h-8.5 px-3 bg-[#222222] hover:bg-[#2c2c2c] text-[#F1F1F1] text-[12px] font-medium rounded-full border border-[#333333] transition-colors"
          title="Add safe videos"
        >
          <Plus className="w-3.5 h-3.5 text-[#FF0000]" />
          <span className="hidden sm:inline">Add</span>
        </a>

        {/* Parent Studio */}
        <a
          href="/studio"
          className="flex items-center gap-1.5 h-8.5 px-3 bg-[#222222] hover:bg-[#2c2c2c] text-[#F1F1F1] text-[12px] font-medium rounded-full border border-[#333333] transition-colors"
          title="Open Parent Studio"
        >
          <Tv className="w-3.5 h-3.5 text-[#3EA6FF]" />
          <span className="hidden sm:inline">Studio</span>
        </a>

        {/* Kid Profile Badge */}
        <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-rose-500 to-amber-500 flex items-center justify-center text-white text-[12px] font-bold shadow-sm shrink-0">
          K
        </div>
      </div>
    </header>
  );
};

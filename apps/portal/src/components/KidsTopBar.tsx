import React, { useState } from 'react';
import { Menu, Sparkles, Search, Plus, ShieldCheck, Lock, X } from 'lucide-react';
import type { ChildProfile } from '@/types/video';

export interface KidsTopBarProps {
  searchQuery?: string;
  onSearchChange?: (q: string) => void;
  onToggleSidebar?: () => void;
  badgeText?: string;
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

  const selectedProfile = profiles.find((p) => p.id === selectedProfileId);

  return (
    <header className="sticky top-0 z-50 flex items-center justify-between h-16 px-3 sm:px-6 bg-[#0B0F19]/90 backdrop-blur-md border-b border-[#1E294B] select-none shadow-sm">
      {/* 1. Left: Hamburger Menu & Bespoke WonderKids Logo */}
      <div className="flex items-center gap-2 sm:gap-3">
        {onToggleSidebar && (
          <button
            onClick={onToggleSidebar}
            aria-label="Toggle navigation sidebar"
            className="p-2 -ml-1 rounded-2xl text-[#94A3B8] hover:text-white hover:bg-[#151D33] transition-all cursor-pointer"
            title="Toggle Sidebar"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}

        <a href="/" className="flex items-center gap-2.5 group select-none">
          {/* Custom Joyful Mascot Emblem (Curved TV with Star) */}
          <div className="relative flex items-center justify-center w-9 h-9 sm:w-10 sm:h-10 bg-gradient-to-tr from-[#FF5E62] via-[#FF8A65] to-[#FFA000] rounded-2xl shadow-md shadow-[#FF5E62]/25 group-hover:scale-105 group-hover:rotate-2 transition-all">
            <Sparkles className="w-5 h-5 text-white fill-current" />
            <span className="absolute -top-1 -right-1 flex h-2.5 w-2.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#FFA000] opacity-75" />
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-[#FFB300]" />
            </span>
          </div>

          <div className="flex flex-col">
            <div className="flex items-center gap-1.5">
              <span className="font-display text-[19px] sm:text-[21px] font-bold tracking-tight text-white leading-none">
                MyKids<span className="text-[#38BDF8]">Tube</span>
              </span>
              <span className="px-2 py-0.5 text-[9.5px] font-extrabold uppercase tracking-wider bg-[#38BDF8]/15 text-[#38BDF8] rounded-full border border-[#38BDF8]/30">
                {badgeText}
              </span>
            </div>
            <span className="text-[10px] font-semibold text-[#64748B] hidden sm:block tracking-wide">
              100% Curated &amp; Safe
            </span>
          </div>
        </a>
      </div>

      {/* 2. Center: Friendly Search Bubble with Soft Glow */}
      <div className="flex-1 max-w-xl mx-4 sm:mx-8 hidden sm:flex items-center justify-center">
        <form onSubmit={handleSearchSubmit} className="flex items-center w-full max-w-md">
          <div className="relative flex-1 flex items-center bg-[#151D33] border border-[#243052] rounded-full focus-within:border-[#38BDF8] focus-within:shadow-[0_0_15px_rgba(56,189,248,0.25)] transition-all">
            <Search className="w-4 h-4 text-[#64748B] ml-3.5 shrink-0" />
            <input
              type="text"
              value={localQuery}
              onChange={(e) => handleQueryChange(e.target.value)}
              placeholder="Search fun cartoons, songs, or games... ✨"
              className="w-full h-10 pl-2.5 pr-8 bg-transparent text-[13.5px] text-white placeholder-[#64748B] outline-none font-medium"
            />
            {localQuery && (
              <button
                type="button"
                onClick={() => handleQueryChange('')}
                className="absolute right-3 text-[#94A3B8] hover:text-white p-1 rounded-full hover:bg-white/10"
                title="Clear"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </form>
      </div>

      {/* 3. Right: Tactile Buttons, Parent Lock & Profile Switcher */}
      <div className="flex items-center gap-2 sm:gap-3">
        {onToggleTapToNext && (
          <button
            onClick={onToggleTapToNext}
            className={`flex items-center gap-1.5 h-9 px-3.5 rounded-full text-[12px] font-bold border transition-all cursor-pointer ${
              tapToNextEnabled
                ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40 shadow-sm'
                : 'bg-[#151D33] text-[#94A3B8] border-[#243052]'
            }`}
            title={tapToNextEnabled ? 'Touch-to-Next: ON' : 'Touch-to-Next: OFF'}
          >
            <Lock className="w-3.5 h-3.5" />
            <span className="hidden md:inline">
              {tapToNextEnabled ? 'Tap Next: ON' : 'Tap Next: OFF'}
            </span>
          </button>
        )}

        {/* Add Wishlist Video */}
        <a
          href="/upload"
          className="flex items-center gap-1.5 h-9 px-3.5 bg-[#151D33] hover:bg-[#1D2845] text-white text-[12.5px] font-bold rounded-full border border-[#243052] transition-all"
          title="Add safe videos"
        >
          <Plus className="w-3.5 h-3.5 text-[#FF5E62]" />
          <span className="hidden sm:inline">Add</span>
        </a>

        {/* Parent Gate Button */}
        <a
          href="/studio"
          className="flex items-center gap-1.5 h-9 px-3.5 bg-gradient-to-r from-indigo-950/80 to-[#151D33] hover:border-[#38BDF8]/50 text-white text-[12.5px] font-bold rounded-full border border-[#243052] transition-all shadow-sm"
          title="Open Parental Controls"
        >
          <ShieldCheck className="w-4 h-4 text-[#38BDF8]" />
          <span className="hidden sm:inline">Parent Studio</span>
        </a>

        {/* Kid Profile Badge with Joyful Glow */}
        <div
          className="w-9 h-9 rounded-full bg-gradient-to-tr from-[#FF5E62] via-[#FFA000] to-[#F472B6] p-0.5 shadow-md shadow-[#FF5E62]/20 shrink-0 cursor-pointer"
          title={selectedProfile ? `Profile: ${selectedProfile.name}` : 'Kid Profile'}
        >
          <div className="w-full h-full bg-[#151D33] rounded-full flex items-center justify-center text-white text-[13px] font-display font-bold">
            {selectedProfile?.name ? selectedProfile.name.charAt(0).toUpperCase() : '⭐'}
          </div>
        </div>
      </div>
    </header>
  );
};

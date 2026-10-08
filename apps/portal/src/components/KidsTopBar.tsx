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
    <header className="sticky top-0 z-50 flex items-center justify-between h-16 px-3 sm:px-6 bg-sidebar/90 backdrop-blur-md border-b border-border select-none shadow-sm">
      {/* 1. Left: Hamburger Menu & Bespoke WonderKids Logo */}
      <div className="flex items-center gap-2 sm:gap-3">
        {onToggleSidebar && (
          <button
            onClick={onToggleSidebar}
            aria-label="Toggle navigation sidebar"
            className="p-2 -ml-1 rounded-2xl text-text-secondary hover:text-text-primary hover:bg-surface transition-all cursor-pointer"
            title="Toggle Sidebar"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}

        <a href="/" className="flex items-center gap-2.5 group select-none">
          {/* Custom Joyful Mascot Emblem (Curved TV with Star) */}
          <div className="relative flex items-center justify-center w-9 h-9 sm:w-10 sm:h-10 bg-gradient-to-tr from-coral via-coral-hover to-sun rounded-2xl shadow-md shadow-coral/25 group-hover:scale-105 group-hover:rotate-2 transition-all">
            <Sparkles className="w-5 h-5 text-white fill-current" />
            <span className="absolute -top-1 -right-1 flex h-2.5 w-2.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-sun opacity-75" />
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-sun" />
            </span>
          </div>

          <div className="flex flex-col">
            <div className="flex items-center gap-1.5">
              <span className="font-display text-[19px] sm:text-[21px] font-bold tracking-tight text-text-primary leading-none">
                MyKids<span className="text-sky">Tube</span>
              </span>
              <span className="px-2 py-0.5 text-[9.5px] font-extrabold uppercase tracking-wider bg-sky/15 text-sky rounded-full border border-sky/30">
                {badgeText}
              </span>
            </div>
            <span className="text-[10px] font-semibold text-text-muted hidden sm:block tracking-wide">
              100% Curated &amp; Safe
            </span>
          </div>
        </a>
      </div>

      {/* 2. Center: Friendly Search Bubble with Soft Glow */}
      <div className="flex-1 max-w-xl mx-4 sm:mx-8 hidden sm:flex items-center justify-center">
        <form onSubmit={handleSearchSubmit} className="flex items-center w-full max-w-md">
          <div className="relative flex-1 flex items-center bg-surface border border-border-strong rounded-full focus-within:border-sky focus-within:shadow-[0_0_15px_rgba(56,189,248,0.25)] transition-all">
            <Search className="w-4 h-4 text-text-muted ml-3.5 shrink-0" />
            <input
              type="text"
              value={localQuery}
              onChange={(e) => handleQueryChange(e.target.value)}
              placeholder="Search fun cartoons, songs, or games... ✨"
              className="w-full h-10 pl-2.5 pr-8 bg-transparent text-[13.5px] text-text-primary placeholder-text-muted outline-none font-medium"
            />
            {localQuery && (
              <button
                type="button"
                onClick={() => handleQueryChange('')}
                className="absolute right-3 text-text-secondary hover:text-text-primary p-1 rounded-full hover:bg-white/10"
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
                ? 'bg-mint/20 text-mint border-mint/40 shadow-sm'
                : 'bg-surface text-text-secondary border-border-strong'
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
          className="flex items-center gap-1.5 h-9 px-3.5 bg-surface hover:bg-surface-elevated text-text-primary text-[12.5px] font-bold rounded-full border border-border-strong transition-all"
          title="Add safe videos"
        >
          <Plus className="w-3.5 h-3.5 text-coral" />
          <span className="hidden sm:inline">Add</span>
        </a>

        {/* Parent Gate Button */}
        <a
          href="/studio"
          className="flex items-center gap-1.5 h-9 px-3.5 bg-surface hover:border-sky/50 text-text-primary text-[12.5px] font-bold rounded-full border border-border-strong transition-all shadow-sm"
          title="Open Parental Controls"
        >
          <ShieldCheck className="w-4 h-4 text-sky" />
          <span className="hidden sm:inline">Parent Studio</span>
        </a>

        {/* Kid Profile Badge with Joyful Glow */}
        <div
          className="w-9 h-9 rounded-full bg-gradient-to-tr from-coral via-sun to-bubblegum p-0.5 shadow-md shadow-coral/20 shrink-0 cursor-pointer"
          title={selectedProfile ? `Profile: ${selectedProfile.name}` : 'Kid Profile'}
        >
          <div className="w-full h-full bg-surface rounded-full flex items-center justify-center text-text-primary text-[13px] font-display font-bold">
            {selectedProfile?.name ? selectedProfile.name.charAt(0).toUpperCase() : '⭐'}
          </div>
        </div>
      </div>
    </header>
  );
};

import React, { useState } from 'react';
import { Menu, Sparkles, Search, Plus, ShieldCheck, Lock, X, ArrowLeft } from 'lucide-react';
import type { ChildProfile } from '../types/video';

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
  const [isMobileSearchOpen, setIsMobileSearchOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);

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
    <header className="sticky top-0 z-50 flex items-center justify-between h-16 px-3 sm:px-6 bg-sidebar/95 backdrop-blur-md border-b-2 border-border select-none shadow-sm">
      {/* Mobile Search Overlay */}
      {isMobileSearchOpen ? (
        <div className="flex sm:hidden items-center w-full gap-2 py-2">
          <button
            type="button"
            onClick={() => setIsMobileSearchOpen(false)}
            aria-label="Close search"
            className="p-2 rounded-xl text-text-secondary hover:text-text-primary hover:bg-surface transition-colors cursor-pointer"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <form onSubmit={handleSearchSubmit} className="flex-1 flex items-center">
            <div className="relative flex-1 flex items-center bg-surface border-2 border-border rounded-full focus-within:border-sky transition-all">
              <Search className="w-4 h-4 text-text-muted ml-3 shrink-0" />
              <input
                type="text"
                autoFocus
                value={localQuery}
                onChange={(e) => handleQueryChange(e.target.value)}
                placeholder="Search cartoons, songs... ✨"
                className="w-full h-9 pl-2.5 pr-8 bg-transparent text-xs text-text-primary placeholder-text-muted outline-none font-medium"
              />
              {localQuery && (
                <button
                  type="button"
                  onClick={() => handleQueryChange('')}
                  className="absolute right-2.5 text-text-secondary hover:text-text-primary p-1 rounded-full"
                  title="Clear"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* 1. Left: Hamburger Menu & Bespoke WonderKids Logo */}
          <div className="flex items-center gap-2 sm:gap-3">
            {onToggleSidebar && (
              <button
                onClick={onToggleSidebar}
                aria-label="Toggle navigation sidebar"
                className="p-2 -ml-1 rounded-2xl text-text-secondary hover:text-text-primary hover:bg-surface border border-transparent hover:border-border transition-colors cursor-pointer"
                title="Toggle Sidebar"
              >
                <Menu className="w-5 h-5" />
              </button>
            )}

            <a href="/" className="flex items-center gap-2.5 group select-none no-underline">
              {/* Custom Joyful Mascot Emblem */}
              <div className="relative flex items-center justify-center w-9 h-9 sm:w-10 sm:h-10 bg-gradient-to-tr from-coral via-coral-hover to-sun rounded-2xl shadow-md shadow-coral/25 group-hover:scale-105 group-hover:rotate-2 transition-all">
                <Sparkles className="w-5 h-5 text-white fill-current" />
                <span className="absolute -top-1 -right-1 flex h-2.5 w-2.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-sun opacity-75" />
                  <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-sun" />
                </span>
              </div>

              <div className="flex flex-col">
                <div className="flex items-center gap-1.5 leading-none">
                  <span className="font-display text-[19px] sm:text-[21px] font-bold tracking-tight text-text-primary">
                    MyKids<span className="text-coral">Tube</span>
                  </span>
                  <span className="px-2 py-0.5 text-[9.5px] font-extrabold uppercase tracking-wider bg-sky/15 text-sky rounded-full border border-sky/30">
                    {badgeText}
                  </span>
                </div>
                <span className="text-[10px] font-semibold text-text-muted hidden sm:block tracking-wide mt-0.5">
                  100% Curated &amp; Safe
                </span>
              </div>
            </a>
          </div>

          {/* 2. Center: Friendly Search Bubble with Soft Glow */}
          <div className="flex-1 max-w-xl mx-4 sm:mx-8 hidden sm:flex items-center justify-center">
            <form onSubmit={handleSearchSubmit} className="flex items-center w-full max-w-md">
              <div className="relative flex-1 flex items-center bg-surface border-2 border-border rounded-full focus-within:border-sky focus-within:shadow-[0_0_15px_rgba(56,189,248,0.25)] transition-all">
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

          {/* 3. Right: Tactile Action Buttons, Parent Gate & Profile */}
          <div className="flex items-center gap-2 sm:gap-3">
            {/* Mobile Search Toggle */}
            <button
              type="button"
              onClick={() => setIsMobileSearchOpen(true)}
              className="sm:hidden p-2 text-text-secondary hover:text-text-primary rounded-xl hover:bg-surface border border-transparent hover:border-border transition-colors cursor-pointer"
              title="Search"
            >
              <Search className="w-4 h-4" />
            </button>

            {/* Optional Touch-to-Next Mode Toggle */}
            {onToggleTapToNext && (
              <button
                onClick={onToggleTapToNext}
                className={`flex items-center gap-1.5 h-9 px-3.5 rounded-full text-[12px] font-bold border transition-all cursor-pointer ${
                  tapToNextEnabled
                    ? 'bg-mint/20 text-mint border-mint/40 shadow-sm'
                    : 'bg-surface text-text-secondary border-border hover:border-border-strong hover:text-text-primary'
                }`}
                title={tapToNextEnabled ? 'Touch-to-Next: ON (Touching screen advances video)' : 'Touch-to-Next: OFF'}
              >
                <Lock className="w-3.5 h-3.5" />
                <span className="hidden md:inline">
                  {tapToNextEnabled ? 'Tap Next: ON' : 'Tap Next: OFF'}
                </span>
              </button>
            )}

            {/* Add Video Button */}
            <a
              href="/upload"
              className="flex items-center gap-1.5 h-9 px-3.5 bg-surface hover:bg-surface-elevated text-text-primary text-[12.5px] font-bold rounded-full border border-border hover:border-coral/50 transition-all no-underline shadow-sm"
              title="Add safe videos"
            >
              <Plus className="w-3.5 h-3.5 text-coral" />
              <span className="hidden sm:inline">Add</span>
            </a>

            {/* Parent Studio Button */}
            <a
              href="/studio"
              className="flex items-center gap-1.5 h-9 px-3.5 bg-surface hover:bg-surface-elevated text-text-primary text-[12.5px] font-bold rounded-full border border-border hover:border-sky/50 transition-all no-underline shadow-sm"
              title="Open Parental Controls"
            >
              <ShieldCheck className="w-4 h-4 text-sky" />
              <span className="hidden sm:inline">Parent Studio</span>
            </a>

            {/* Kid Profile Badge with Joyful Rainbow Glow & Dropdown */}
            <div className="relative">
              <button
                type="button"
                onClick={() => profiles.length > 0 && setIsProfileMenuOpen((prev) => !prev)}
                className="w-9 h-9 rounded-full bg-gradient-to-tr from-coral via-sun to-bubblegum p-0.5 shadow-md shadow-coral/20 shrink-0 cursor-pointer focus:outline-none hover:scale-105 transition-transform"
                title={selectedProfile ? `Profile: ${selectedProfile.name}` : 'Kid Profile'}
              >
                <div className="w-full h-full bg-surface rounded-full flex items-center justify-center text-text-primary text-[13px] font-display font-bold">
                  {selectedProfile?.name ? selectedProfile.name.charAt(0).toUpperCase() : '⭐'}
                </div>
              </button>

              {isProfileMenuOpen && profiles.length > 0 && (
                <>
                  <div
                    className="fixed inset-0 z-40"
                    onClick={() => setIsProfileMenuOpen(false)}
                  />
                  <div className="absolute right-0 mt-2 w-48 bg-surface border-2 border-border rounded-2xl shadow-xl z-50 p-1.5 animate-in fade-in zoom-in-95 duration-100">
                    <div className="px-3 py-1.5 text-[11px] font-extrabold uppercase tracking-wider text-text-muted">
                      Switch Profile
                    </div>
                    {profiles.map((p) => {
                      const isSelected = p.id === selectedProfileId;
                      return (
                        <button
                          key={p.id}
                          onClick={() => {
                            onProfileSelect?.(p.id);
                            setIsProfileMenuOpen(false);
                          }}
                          className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-bold transition-colors cursor-pointer ${
                            isSelected
                              ? 'bg-coral/15 text-coral'
                              : 'text-text-secondary hover:text-text-primary hover:bg-surface-elevated'
                          }`}
                        >
                          <div className="w-6 h-6 rounded-full bg-gradient-to-tr from-coral to-sun flex items-center justify-center text-white text-[11px] font-display font-black">
                            {p.name.charAt(0).toUpperCase()}
                          </div>
                          <span className="truncate">{p.name}</span>
                        </button>
                      );
                    })}
                  </div>
                </>
              )}
            </div>
          </div>
        </>
      )}
    </header>
  );
};

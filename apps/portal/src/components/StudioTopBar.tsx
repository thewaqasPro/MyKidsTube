import React from 'react';
import { Menu, Search, Plus, Home, Shield, HardDrive, Sparkles } from 'lucide-react';

export interface StudioTopBarProps {
  onToggleSidebar?: () => void;
  searchQuery?: string;
  onSearchChange?: (q: string) => void;
  storageUsedGb?: number;
  storageTotalGb?: number;
}

export const StudioTopBar: React.FC<StudioTopBarProps> = ({
  onToggleSidebar,
  searchQuery = '',
  onSearchChange,
  storageUsedGb = 0.8,
  storageTotalGb = 80,
}) => {
  return (
    <header className="sticky top-0 z-50 flex items-center justify-between h-16 px-4 sm:px-6 bg-sidebar border-b-2 border-border select-none shadow-sm">
      {/* 1. Left: Hamburger & Studio Brand */}
      <div className="flex items-center gap-2 sm:gap-3">
        {onToggleSidebar && (
          <button
            onClick={onToggleSidebar}
            aria-label="Toggle studio sidebar"
            className="p-2 -ml-1 rounded-2xl text-text-secondary hover:text-text-primary hover:bg-surface border border-transparent hover:border-border transition-colors cursor-pointer"
            title="Toggle Studio Sidebar"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}

        <a href="/studio" className="flex items-center gap-3 group select-none no-underline">
          <div className="relative flex items-center justify-center w-9 h-8 rounded-xl bg-gradient-to-tr from-coral to-sun text-white shadow-md shadow-coral/30 group-hover:scale-105 transition-transform">
            <span className="font-display font-black text-xs text-white">WK</span>
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-1.5 leading-none">
              <span className="font-display font-black text-lg tracking-wide text-text-primary">
                MyKids<span className="text-coral">Tube</span>
              </span>
              <span className="text-[11px] font-black px-2 py-0.5 rounded-full bg-sky/15 text-sky border border-sky/30">
                Parent Hub
              </span>
            </div>
            <span className="text-[10px] text-text-secondary font-semibold tracking-wide">
              Family Content & Safety Controls
            </span>
          </div>
        </a>
      </div>

      {/* 2. Center: Search in Studio */}
      <div className="flex-1 max-w-md mx-4 hidden md:flex items-center justify-center">
        <div className="relative w-full flex items-center bg-surface border-2 border-border rounded-full focus-within:border-sky transition-colors">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange && onSearchChange(e.target.value)}
            placeholder="Search catalog videos, IDs, tags..."
            className="w-full h-9 pl-4 pr-10 bg-transparent text-xs text-text-primary placeholder-text-muted outline-none font-medium"
          />
          <div className="absolute right-3.5 text-text-secondary">
            <Search className="w-4 h-4" />
          </div>
        </div>
      </div>

      {/* 3. Right: Storage Status, Add Video & Switch to Kids App */}
      <div className="flex items-center gap-2.5 sm:gap-3">
        {/* VPS Storage Badge */}
        <div className="hidden lg:flex items-center gap-2 px-3.5 py-1.5 bg-surface border border-border rounded-full text-xs">
          <HardDrive className="w-3.5 h-3.5 text-sky" />
          <span className="text-text-secondary font-medium">Storage:</span>
          <span className="font-mono text-text-primary font-bold">
            {storageUsedGb.toFixed(1)} GB / {storageTotalGb} GB
          </span>
          <span className="w-2 h-2 rounded-full bg-mint animate-pulse ml-0.5 shadow-sm shadow-mint" />
        </div>

        {/* Add Video Button */}
        <a
          href="/upload"
          className="flex items-center gap-1.5 h-9 px-4 bg-gradient-to-r from-coral to-coral-hover text-white text-xs font-display font-black rounded-full transition-all shadow-md shadow-coral/20 no-underline active:scale-95"
          title="Add new video to wishlist"
        >
          <Plus className="w-4 h-4" />
          <span className="hidden sm:inline">Add Video</span>
        </a>

        {/* Exit to Kids App Button */}
        <a
          href="/"
          className="flex items-center gap-1.5 h-9 px-4 bg-surface hover:bg-surface-elevated text-text-secondary hover:text-text-primary text-xs font-bold rounded-full border-2 border-border transition-colors no-underline active:scale-95"
          title="Return to KidsTube Frontend"
        >
          <Home className="w-3.5 h-3.5 text-sky" />
          <span className="hidden sm:inline">Kids App</span>
        </a>

        {/* Parent Admin Avatar */}
        <div className="w-9 h-9 rounded-2xl bg-gradient-to-tr from-sky to-violet flex items-center justify-center text-white text-xs font-black shadow-md shrink-0 border-2 border-white/20">
          <Shield className="w-4 h-4 text-white" />
        </div>
      </div>
    </header>
  );
};

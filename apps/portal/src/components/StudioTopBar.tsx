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
    <header className="sticky top-0 z-50 flex items-center justify-between h-16 px-4 sm:px-6 bg-[#0B0F19] border-b-2 border-[#1E294B] select-none shadow-sm">
      {/* 1. Left: Hamburger & Studio Brand */}
      <div className="flex items-center gap-2 sm:gap-3">
        {onToggleSidebar && (
          <button
            onClick={onToggleSidebar}
            aria-label="Toggle studio sidebar"
            className="p-2 -ml-1 rounded-2xl text-[#94A3B8] hover:text-white hover:bg-[#151D33] border border-transparent hover:border-[#1E294B] transition-colors cursor-pointer"
            title="Toggle Studio Sidebar"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}

        <a href="/studio" className="flex items-center gap-3 group select-none no-underline">
          <div className="relative flex items-center justify-center w-9 h-8 rounded-xl bg-gradient-to-tr from-[#FF5E62] to-[#FFB300] text-white shadow-md shadow-[#FF5E62]/30 group-hover:scale-105 transition-transform">
            <span className="font-display font-black text-xs text-white">WK</span>
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-1.5 leading-none">
              <span className="font-display font-black text-lg tracking-wide text-white">
                MyKids<span className="text-[#FF5E62]">Tube</span>
              </span>
              <span className="text-[11px] font-black px-2 py-0.5 rounded-full bg-[#38BDF8]/15 text-[#38BDF8] border border-[#38BDF8]/30">
                Parent Hub
              </span>
            </div>
            <span className="text-[10px] text-[#94A3B8] font-semibold tracking-wide">
              Family Content & Safety Controls
            </span>
          </div>
        </a>
      </div>

      {/* 2. Center: Search in Studio */}
      <div className="flex-1 max-w-md mx-4 hidden md:flex items-center justify-center">
        <div className="relative w-full flex items-center bg-[#151D33] border-2 border-[#1E294B] rounded-full focus-within:border-[#38BDF8] transition-colors">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange && onSearchChange(e.target.value)}
            placeholder="Search catalog videos, IDs, tags..."
            className="w-full h-9 pl-4 pr-10 bg-transparent text-xs text-white placeholder-[#64748B] outline-none font-medium"
          />
          <div className="absolute right-3.5 text-[#94A3B8]">
            <Search className="w-4 h-4" />
          </div>
        </div>
      </div>

      {/* 3. Right: Storage Status, Add Video & Switch to Kids App */}
      <div className="flex items-center gap-2.5 sm:gap-3">
        {/* VPS Storage Badge */}
        <div className="hidden lg:flex items-center gap-2 px-3.5 py-1.5 bg-[#151D33] border border-[#1E294B] rounded-full text-xs">
          <HardDrive className="w-3.5 h-3.5 text-[#38BDF8]" />
          <span className="text-[#94A3B8] font-medium">Storage:</span>
          <span className="font-mono text-white font-bold">
            {storageUsedGb.toFixed(1)} GB / {storageTotalGb} GB
          </span>
          <span className="w-2 h-2 rounded-full bg-[#10B981] animate-pulse ml-0.5 shadow-sm shadow-[#10B981]" />
        </div>

        {/* Add Video Button */}
        <a
          href="/upload"
          className="flex items-center gap-1.5 h-9 px-4 bg-gradient-to-r from-[#FF5E62] to-[#FF8E53] hover:from-[#FF8E53] hover:to-[#FF5E62] text-white text-xs font-display font-black rounded-full transition-all shadow-md shadow-[#FF5E62]/20 no-underline active:scale-95"
          title="Add new video to wishlist"
        >
          <Plus className="w-4 h-4" />
          <span className="hidden sm:inline">Add Video</span>
        </a>

        {/* Exit to Kids App Button */}
        <a
          href="/"
          className="flex items-center gap-1.5 h-9 px-4 bg-[#151D33] hover:bg-[#1E294B] text-[#94A3B8] hover:text-white text-xs font-bold rounded-full border-2 border-[#1E294B] transition-colors no-underline active:scale-95"
          title="Return to KidsTube Frontend"
        >
          <Home className="w-3.5 h-3.5 text-[#38BDF8]" />
          <span className="hidden sm:inline">Kids App</span>
        </a>

        {/* Parent Admin Avatar */}
        <div className="w-9 h-9 rounded-2xl bg-gradient-to-tr from-[#38BDF8] to-[#A855F7] flex items-center justify-center text-white text-xs font-black shadow-md shrink-0 border-2 border-white/20">
          <Shield className="w-4 h-4 text-white" />
        </div>
      </div>
    </header>
  );
};

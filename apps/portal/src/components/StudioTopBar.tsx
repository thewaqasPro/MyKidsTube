import React from 'react';
import { Menu, Tv, Search, Plus, Home, Shield, HardDrive } from 'lucide-react';

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
    <header className="sticky top-0 z-50 flex items-center justify-between h-14 px-3 sm:px-6 bg-[#0F0F0F] border-b border-[#222222] select-none">
      {/* 1. Left: Hamburger & Studio Brand */}
      <div className="flex items-center gap-2 sm:gap-3">
        {onToggleSidebar && (
          <button
            onClick={onToggleSidebar}
            aria-label="Toggle studio sidebar"
            className="p-2 -ml-1 rounded-full text-[#AAAAAA] hover:text-white hover:bg-[#222222] transition-colors cursor-pointer"
            title="Toggle Studio Sidebar"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}

        <a href="/studio" className="flex items-center gap-2.5 group select-none">
          <div className="flex items-center justify-center w-8 h-8 bg-gradient-to-tr from-[#FF0000] to-rose-600 rounded-lg shadow-sm group-hover:scale-105 transition-transform">
            <Tv className="w-4 h-4 text-white" />
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-1.5 leading-none">
              <span className="text-[17px] font-bold tracking-tight text-white font-sans">
                Kids<span className="text-[#FF0000]">Tube</span>
              </span>
              <span className="text-[12px] font-semibold text-[#3EA6FF]">Studio</span>
            </div>
            <span className="text-[10px] text-[#888888] font-medium tracking-wide">
              Parent Control Center
            </span>
          </div>
        </a>
      </div>

      {/* 2. Center: Search in Studio */}
      <div className="flex-1 max-w-md mx-4 hidden md:flex items-center justify-center">
        <div className="relative w-full flex items-center bg-[#121212] border border-[#303030] rounded-full focus-within:border-[#3EA6FF] transition-colors">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange && onSearchChange(e.target.value)}
            placeholder="Search catalog videos, IDs, tags..."
            className="w-full h-8.5 pl-4 pr-10 bg-transparent text-[13px] text-white placeholder-[#717171] outline-none"
          />
          <div className="absolute right-3 text-[#AAAAAA]">
            <Search className="w-4 h-4" />
          </div>
        </div>
      </div>

      {/* 3. Right: Storage Status, Add Video & Switch to Kids App */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* VPS Storage Badge */}
        <div className="hidden lg:flex items-center gap-2 px-3 py-1 bg-[#161616] border border-[#262626] rounded-full text-[11px]">
          <HardDrive className="w-3.5 h-3.5 text-[#3EA6FF]" />
          <span className="text-[#888888]">VPS Disk:</span>
          <span className="font-mono text-white font-medium">
            {storageUsedGb.toFixed(1)} GB / {storageTotalGb} GB
          </span>
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse ml-0.5" />
        </div>

        {/* Add Video Button */}
        <a
          href="/upload"
          className="flex items-center gap-1.5 h-8.5 px-3 bg-[#FF0000] hover:bg-[#CC0000] text-white text-[12px] font-semibold rounded-full transition-colors shadow-sm"
          title="Add new video to wishlist"
        >
          <Plus className="w-3.5 h-3.5" />
          <span className="hidden sm:inline">Add Video</span>
        </a>

        {/* Exit to Kids App Button */}
        <a
          href="/"
          className="flex items-center gap-1.5 h-8.5 px-3 bg-[#222222] hover:bg-[#2c2c2c] text-[#DDDDDD] hover:text-white text-[12px] font-medium rounded-full border border-[#333333] transition-colors"
          title="Return to KidsTube Frontend"
        >
          <Home className="w-3.5 h-3.5" />
          <span className="hidden sm:inline">Kids App</span>
        </a>

        {/* Parent Admin Avatar */}
        <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center text-white text-[12px] font-bold shadow-sm shrink-0 border border-blue-400/30">
          <Shield className="w-4 h-4 text-white" />
        </div>
      </div>
    </header>
  );
};

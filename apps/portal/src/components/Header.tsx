import React, { useState } from 'react';
import { Search, Plus, Tv, Cookie, X, User, Menu } from 'lucide-react';
import type { ChildProfile } from '../types/video';

interface HeaderProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
  profiles: ChildProfile[];
  selectedProfileId: string;
  onProfileSelect: (id: string) => void;
  onOpenIngest: () => void;
  onOpenPair: () => void;
  onOpenCookies: () => void;
  onToggleSidebar?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  searchQuery,
  onSearchChange,
  profiles,
  selectedProfileId,
  onProfileSelect,
  onOpenIngest,
  onOpenPair,
  onOpenCookies,
  onToggleSidebar,
}) => {
  const [profileDropdownOpen, setProfileDropdownOpen] = useState(false);
  const activeProfile = profiles.find((p) => p.id === selectedProfileId) || profiles[0];

  return (
    <header className="sticky top-0 z-30 flex items-center justify-between h-14 px-4 sm:px-6 bg-[#0F0F0F]/95 backdrop-blur-md border-b border-[#222222]">
      {/* Left: Brand Logo & Navigation Toggle */}
      <div className="flex items-center gap-2 sm:gap-3">
        {onToggleSidebar && (
          <button
            onClick={onToggleSidebar}
            aria-label="Toggle navigation drawer"
            className="p-2 -ml-1 rounded-full text-[#AAAAAA] hover:text-white hover:bg-[#222222] transition-colors"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}

        <a href="/" className="flex items-center gap-2 group select-none">
          <div className="relative flex items-center justify-center w-9 h-6.5 bg-[#FF0000] rounded-lg shadow-sm group-hover:scale-105 transition-transform">
            <svg
              className="w-3.5 h-3.5 text-white fill-current ml-0.5"
              viewBox="0 0 24 24"
            >
              <path d="M8 5v14l11-7z" />
            </svg>
          </div>
          <div className="flex items-center">
            <span className="text-[19px] font-bold tracking-tighter text-white font-sans">
              Kids<span className="text-[#FF0000]">Tube</span>
            </span>
            <span className="ml-1.5 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wider bg-[#222222] text-[#AAAAAA] rounded border border-[#303030]">
              Safe
            </span>
          </div>
        </a>
      </div>

      {/* Center: Search Bar */}
      <div className="flex-1 max-w-xl mx-4 hidden sm:block">
        <div className="relative flex items-center">
          <div className="relative w-full flex items-center bg-[#121212] border border-[#303030] rounded-full focus-within:border-[#3EA6FF] focus-within:bg-[#0F0F0F] transition-all">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              placeholder="Search safe videos & songs..."
              className="w-full h-10 pl-4 pr-10 bg-transparent text-[14px] text-[#F1F1F1] placeholder-[#717171] rounded-full outline-none"
            />
            {searchQuery ? (
              <button
                onClick={() => onSearchChange('')}
                className="absolute right-12 text-[#AAAAAA] hover:text-white p-1"
                aria-label="Clear search"
              >
                <X className="w-4 h-4" />
              </button>
            ) : null}
            <div className="h-10 px-5 flex items-center justify-center bg-[#222222] border-l border-[#303030] rounded-r-full text-[#AAAAAA] hover:text-white hover:bg-[#272727] cursor-pointer">
              <Search className="w-4 h-4" />
            </div>
          </div>
        </div>
      </div>

      {/* Right: Actions & Profile */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Mobile Search Input trigger */}
        <div className="sm:hidden flex items-center">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Search..."
            className="w-32 h-8 px-2.5 bg-[#1f1f1f] border border-[#333] text-[12px] text-white rounded-full outline-none focus:w-44 transition-all"
          />
        </div>

        {/* Add Video Button */}
        <button
          onClick={onOpenIngest}
          className="flex items-center gap-1.5 h-9 px-3.5 bg-[#272727] hover:bg-[#383838] active:scale-95 text-[#F1F1F1] text-[13px] font-medium rounded-full border border-[#333333] transition-all cursor-pointer"
          title="Add YouTube video or playlist"
        >
          <Plus className="w-4 h-4 text-[#FF0000]" />
          <span className="hidden md:inline">Add Video</span>
        </button>

        {/* Pair TV / Tablet */}
        <button
          onClick={onOpenPair}
          className="flex items-center gap-1.5 h-9 px-3 bg-[#272727] hover:bg-[#383838] active:scale-95 text-[#F1F1F1] text-[13px] font-medium rounded-full border border-[#333333] transition-all cursor-pointer"
          title="Pair TV or Tablet App"
        >
          <Tv className="w-4 h-4 text-[#3EA6FF]" />
          <span className="hidden lg:inline">Pair Device</span>
        </button>

        {/* YouTube Cookies */}
        <button
          onClick={onOpenCookies}
          className="flex items-center justify-center w-9 h-9 bg-[#272727] hover:bg-[#383838] text-[#AAAAAA] hover:text-white rounded-full border border-[#333333] transition-all cursor-pointer"
          title="YouTube Cookies Status"
        >
          <Cookie className="w-4 h-4 text-amber-400" />
        </button>

        {/* Profile Selector Dropdown */}
        <div className="relative">
          <button
            onClick={() => setProfileDropdownOpen(!profileDropdownOpen)}
            className="flex items-center gap-2 h-9 pl-2 pr-3 bg-[#222222] hover:bg-[#2a2a2a] rounded-full border border-[#333333] text-[13px] text-white font-medium cursor-pointer transition-colors"
          >
            <div className="w-6 h-6 rounded-full bg-gradient-to-tr from-rose-500 to-amber-500 flex items-center justify-center text-white text-[11px] font-bold">
              {activeProfile ? activeProfile.name.charAt(0) : 'K'}
            </div>
            <span className="hidden sm:inline max-w-[80px] truncate">
              {activeProfile ? activeProfile.name : 'Profile'}
            </span>
          </button>

          {profileDropdownOpen && (
            <div className="absolute right-0 mt-2 w-48 bg-[#222222] border border-[#383838] rounded-xl shadow-2xl py-1 z-50 animate-in fade-in zoom-in-95 duration-100">
              <div className="px-3 py-2 border-b border-[#303030] text-[11px] font-semibold text-[#888888] uppercase tracking-wider">
                Select Child Profile
              </div>
              {profiles.map((p) => (
                <button
                  key={p.id}
                  onClick={() => {
                    onProfileSelect(p.id);
                    setProfileDropdownOpen(false);
                  }}
                  className={`w-full flex items-center gap-2.5 px-3 py-2 text-left text-[13px] hover:bg-[#333333] transition-colors cursor-pointer ${
                    p.id === selectedProfileId ? 'text-[#3EA6FF] font-semibold' : 'text-[#F1F1F1]'
                  }`}
                >
                  <User className="w-4 h-4 opacity-70" />
                  <span className="truncate">{p.name}</span>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </header>
  );
};

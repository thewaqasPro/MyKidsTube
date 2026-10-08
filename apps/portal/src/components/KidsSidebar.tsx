import React from 'react';
import { Home, Zap, Heart, Compass, ShieldCheck, Sparkles, Tv } from 'lucide-react';

export interface ChannelItem {
  name: string;
  icon?: string;
  count?: number;
}

export interface KidsSidebarProps {
  isExpanded: boolean;
  isMobileOpen: boolean;
  onCloseMobile: () => void;
  activeNav?: string; // 'home' | 'shorts' | 'watch' | 'channels' | 'favorites' | 'studio'
  onSelectNav?: (nav: string) => void;
  channels?: ChannelItem[] | string[];
}

export const KidsSidebar: React.FC<KidsSidebarProps> = ({
  isExpanded,
  isMobileOpen,
  onCloseMobile,
  activeNav = 'home',
  onSelectNav,
  channels = [],
}) => {
  const normalizedChannels: ChannelItem[] = channels.map((c) =>
    typeof c === 'string' ? { name: c } : c
  );

  const handleNavClick = (id: string, href?: string) => {
    if (onSelectNav) {
      onSelectNav(id);
    }
    onCloseMobile();
    if (href && typeof window !== 'undefined') {
      window.location.href = href;
    }
  };

  return (
    <>
      {/* 1. Mobile Backdrop */}
      {isMobileOpen && (
        <div
          onClick={onCloseMobile}
          className="fixed inset-0 z-40 bg-black/75 backdrop-blur-sm lg:hidden transition-opacity"
        />
      )}

      {/* 2. WonderKids Sidebar Body */}
      <aside
        className={`shrink-0 z-40 bg-[#0B0F19] border-r border-[#1E294B] select-none flex flex-col transition-all duration-200 ${
          isMobileOpen
            ? 'fixed top-16 bottom-0 left-0 w-64 shadow-2xl z-50'
            : isExpanded
            ? 'w-64 hidden lg:flex'
            : 'w-[78px] hidden md:flex'
        }`}
      >
        <div className="py-4 px-3 flex flex-col gap-2 flex-1 overflow-y-auto custom-scrollbar">
          {/* Nav Item 1: Home */}
          <a
            href="/"
            onClick={(e) => {
              if (onSelectNav) {
                e.preventDefault();
                handleNavClick('home', '/');
              }
            }}
            className={`flex items-center rounded-2xl transition-all ${
              isExpanded || isMobileOpen
                ? 'px-3.5 py-3 gap-3.5 justify-start'
                : 'flex-col py-3 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'home'
                ? 'bg-[#151D33] text-white border border-[#38BDF8]/40 shadow-sm shadow-[#38BDF8]/10'
                : 'text-[#94A3B8] hover:text-white hover:bg-[#151D33]/60'
            }`}
            title="Home"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'home' ? 'bg-[#38BDF8] text-[#0B0F19]' : 'bg-[#151D33] text-[#38BDF8]'}`}>
              <Home className="w-4 h-4" />
            </div>
            <span className={`font-display tracking-wide ${isExpanded || isMobileOpen ? 'text-[14px] font-bold' : 'text-[11px] font-semibold'}`}>
              Home
            </span>
          </a>

          {/* Nav Item 2: Shorts & Fun Reels */}
          <a
            href="/shorts"
            onClick={(e) => {
              if (onSelectNav) {
                e.preventDefault();
                handleNavClick('shorts', '/shorts');
              }
            }}
            className={`flex items-center rounded-2xl transition-all ${
              isExpanded || isMobileOpen
                ? 'px-3.5 py-3 gap-3.5 justify-start'
                : 'flex-col py-3 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'shorts'
                ? 'bg-[#151D33] text-white border border-[#FF5E62]/40 shadow-sm shadow-[#FF5E62]/10'
                : 'text-[#94A3B8] hover:text-white hover:bg-[#151D33]/60'
            }`}
            title="Shorts"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'shorts' ? 'bg-[#FF5E62] text-white' : 'bg-[#151D33] text-[#FF5E62]'}`}>
              <Zap className="w-4 h-4 fill-current" />
            </div>
            <span className={`font-display tracking-wide ${isExpanded || isMobileOpen ? 'text-[14px] font-bold' : 'text-[11px] font-semibold'}`}>
              Fun Reels
            </span>
          </a>

          {/* Nav Item 3: Favorites */}
          <a
            href="/"
            onClick={(e) => {
              if (onSelectNav) {
                e.preventDefault();
                handleNavClick('favorites', '/');
              }
            }}
            className={`flex items-center rounded-2xl transition-all ${
              isExpanded || isMobileOpen
                ? 'px-3.5 py-3 gap-3.5 justify-start'
                : 'flex-col py-3 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'favorites'
                ? 'bg-[#151D33] text-white border border-[#FFB300]/40 shadow-sm shadow-[#FFB300]/10'
                : 'text-[#94A3B8] hover:text-white hover:bg-[#151D33]/60'
            }`}
            title="Favorites"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'favorites' ? 'bg-[#FFB300] text-[#0B0F19]' : 'bg-[#151D33] text-[#FFB300]'}`}>
              <Heart className="w-4 h-4 fill-current" />
            </div>
            <span className={`font-display tracking-wide ${isExpanded || isMobileOpen ? 'text-[14px] font-bold' : 'text-[11px] font-semibold'}`}>
              Favorites
            </span>
          </a>

          {/* Nav Item 4: Channels */}
          <a
            href="/"
            onClick={(e) => {
              if (onSelectNav) {
                e.preventDefault();
                handleNavClick('channels', '/');
              }
            }}
            className={`flex items-center rounded-2xl transition-all ${
              isExpanded || isMobileOpen
                ? 'px-3.5 py-3 gap-3.5 justify-start'
                : 'flex-col py-3 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'channels'
                ? 'bg-[#151D33] text-white border border-[#10B981]/40 shadow-sm shadow-[#10B981]/10'
                : 'text-[#94A3B8] hover:text-white hover:bg-[#151D33]/60'
            }`}
            title="Channels"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'channels' ? 'bg-[#10B981] text-white' : 'bg-[#151D33] text-[#10B981]'}`}>
              <Tv className="w-4 h-4" />
            </div>
            <span className={`font-display tracking-wide ${isExpanded || isMobileOpen ? 'text-[14px] font-bold' : 'text-[11px] font-semibold'}`}>
              Channels
            </span>
          </a>

          {/* Nav Item 5: Parent Studio */}
          <a
            href="/studio"
            className={`flex items-center rounded-2xl transition-all ${
              isExpanded || isMobileOpen
                ? 'px-3.5 py-3 gap-3.5 justify-start'
                : 'flex-col py-3 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'studio'
                ? 'bg-[#151D33] text-white border border-indigo-400/40 shadow-sm'
                : 'text-[#94A3B8] hover:text-white hover:bg-[#151D33]/60'
            }`}
            title="Parent Studio"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'studio' ? 'bg-indigo-600 text-white' : 'bg-[#151D33] text-indigo-400'}`}>
              <ShieldCheck className="w-4 h-4" />
            </div>
            <span className={`font-display tracking-wide ${isExpanded || isMobileOpen ? 'text-[14px] font-bold' : 'text-[11px] font-semibold'}`}>
              Parent Lock
            </span>
          </a>

          {/* Subscribed Channels Shelf */}
          {(isExpanded || isMobileOpen) && (
            <>
              {normalizedChannels.length > 0 && (
                <div className="mt-4 pt-4 border-t border-[#1E294B]">
                  <span className="px-3.5 text-[11px] font-display font-bold text-[#64748B] uppercase tracking-wider block mb-2.5">
                    Kids Channels
                  </span>
                  <div className="space-y-1">
                    {normalizedChannels.slice(0, 8).map((ch, idx) => {
                      const colors = ['from-pink-500 to-rose-500', 'from-amber-400 to-orange-500', 'from-sky-400 to-blue-600', 'from-emerald-400 to-teal-600', 'from-purple-500 to-indigo-600'];
                      const grad = colors[idx % colors.length];

                      return (
                        <div
                          key={ch.name}
                          onClick={() => handleNavClick(`channel:${ch.name}`)}
                          className="flex items-center gap-3 px-3 py-2 rounded-xl text-[13px] text-[#CBD5E1] hover:text-white hover:bg-[#151D33] transition-all cursor-pointer truncate group"
                        >
                          <div className={`w-7 h-7 rounded-full bg-gradient-to-tr ${grad} flex items-center justify-center text-white text-[11px] font-display font-bold shrink-0 shadow-sm group-hover:scale-105 transition-transform`}>
                            {ch.name.charAt(0)}
                          </div>
                          <span className="truncate font-medium">{ch.name}</span>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Safe Kids Mode Card */}
              <div className="mt-4 pt-4 border-t border-[#1E294B]">
                <div className="p-3.5 rounded-2xl bg-gradient-to-br from-[#151D33] to-[#1A233D] border border-emerald-500/30 shadow-sm">
                  <div className="flex items-center gap-2 text-emerald-400 text-[12.5px] font-display font-bold">
                    <Sparkles className="w-4 h-4 text-emerald-400" />
                    <span>WonderKids Shield</span>
                  </div>
                  <p className="text-[11px] text-[#94A3B8] mt-1.5 leading-relaxed font-sans">
                    100% ad-free &amp; safely verified for happy young minds.
                  </p>
                </div>
              </div>
            </>
          )}
        </div>

        {/* Footer */}
        <div className="p-3 border-t border-[#1E294B] text-[10.5px] font-semibold text-[#64748B] text-center font-display">
          🌟 Safe Play Zone
        </div>
      </aside>
    </>
  );
};

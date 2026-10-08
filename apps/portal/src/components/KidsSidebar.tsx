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
        className={`shrink-0 z-40 bg-sidebar border-r border-border select-none flex flex-col transition-all duration-200 ${
          isMobileOpen
            ? 'fixed top-16 bottom-0 left-0 w-64 shadow-2xl z-50 overflow-y-auto custom-scrollbar'
            : isExpanded
            ? 'sticky top-16 h-[calc(100vh-4rem)] self-start w-64 hidden lg:flex overflow-hidden'
            : 'sticky top-16 h-[calc(100vh-4rem)] self-start w-[76px] hidden md:flex overflow-hidden'
        }`}
      >
        <div className="py-4 px-2.5 flex flex-col gap-2 flex-1 min-h-0 overflow-y-auto custom-scrollbar">
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
                : 'justify-center p-2.5'
            } ${
              activeNav === 'home'
                ? 'bg-surface text-text-primary border border-sky/40 shadow-sm shadow-sky/10'
                : 'text-text-secondary hover:text-text-primary hover:bg-surface/60'
            }`}
            title="Home"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'home' ? 'bg-sky text-sidebar' : 'bg-surface text-sky'}`}>
              <Home className="w-4 h-4" />
            </div>
            {(isExpanded || isMobileOpen) && (
              <span className="font-display tracking-wide text-[14px] font-bold">
                Home
              </span>
            )}
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
                : 'justify-center p-2.5'
            } ${
              activeNav === 'shorts'
                ? 'bg-surface text-text-primary border border-coral/40 shadow-sm shadow-coral/10'
                : 'text-text-secondary hover:text-text-primary hover:bg-surface/60'
            }`}
            title="Fun Reels"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'shorts' ? 'bg-coral text-white' : 'bg-surface text-coral'}`}>
              <Zap className="w-4 h-4 fill-current" />
            </div>
            {(isExpanded || isMobileOpen) && (
              <span className="font-display tracking-wide text-[14px] font-bold">
                Fun Reels
              </span>
            )}
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
                : 'justify-center p-2.5'
            } ${
              activeNav === 'favorites'
                ? 'bg-surface text-text-primary border border-sun/40 shadow-sm shadow-sun/10'
                : 'text-text-secondary hover:text-text-primary hover:bg-surface/60'
            }`}
            title="Favorites"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'favorites' ? 'bg-sun text-sidebar' : 'bg-surface text-sun'}`}>
              <Heart className="w-4 h-4 fill-current" />
            </div>
            {(isExpanded || isMobileOpen) && (
              <span className="font-display tracking-wide text-[14px] font-bold">
                Favorites
              </span>
            )}
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
                : 'justify-center p-2.5'
            } ${
              activeNav === 'channels'
                ? 'bg-surface text-text-primary border border-mint/40 shadow-sm shadow-mint/10'
                : 'text-text-secondary hover:text-text-primary hover:bg-surface/60'
            }`}
            title="Channels"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'channels' ? 'bg-mint text-white' : 'bg-surface text-mint'}`}>
              <Tv className="w-4 h-4" />
            </div>
            {(isExpanded || isMobileOpen) && (
              <span className="font-display tracking-wide text-[14px] font-bold">
                Channels
              </span>
            )}
          </a>

          {/* Nav Item 5: Parent Studio */}
          <a
            href="/studio"
            className={`flex items-center rounded-2xl transition-all ${
              isExpanded || isMobileOpen
                ? 'px-3.5 py-3 gap-3.5 justify-start'
                : 'justify-center p-2.5'
            } ${
              activeNav === 'studio'
                ? 'bg-surface text-text-primary border border-violet/40 shadow-sm'
                : 'text-text-secondary hover:text-text-primary hover:bg-surface/60'
            }`}
            title="Parent Lock"
          >
            <div className={`p-2 rounded-xl shrink-0 ${activeNav === 'studio' ? 'bg-violet text-white' : 'bg-surface text-violet'}`}>
              <ShieldCheck className="w-4 h-4" />
            </div>
            {(isExpanded || isMobileOpen) && (
              <span className="font-display tracking-wide text-[14px] font-bold">
                Parent Lock
              </span>
            )}
          </a>

          {/* Subscribed Channels Shelf */}
          {(isExpanded || isMobileOpen) && (
            <>
              {normalizedChannels.length > 0 && (
                <div className="mt-4 pt-4 border-t border-border">
                  <span className="px-3.5 text-[11px] font-display font-bold text-text-muted uppercase tracking-wider block mb-2.5">
                    Kids Channels
                  </span>
                  <div className="space-y-1">
                    {normalizedChannels.slice(0, 8).map((ch, idx) => {
                      const colors = ['from-pink-500 to-rose-500', 'from-amber-400 to-orange-500', 'from-sky to-blue-600', 'from-emerald-400 to-teal-600', 'from-violet to-indigo-600'];
                      const grad = colors[idx % colors.length];

                      return (
                        <div
                          key={ch.name}
                          onClick={() => handleNavClick(`channel:${ch.name}`)}
                          className="flex items-center gap-3 px-3 py-2 rounded-xl text-[13px] text-text-secondary hover:text-text-primary hover:bg-surface transition-all cursor-pointer truncate group"
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
              <div className="mt-4 pt-4 border-t border-border">
                <div className="p-3.5 rounded-2xl bg-gradient-to-br from-surface to-surface-elevated border border-mint/30 shadow-sm">
                  <div className="flex items-center gap-2 text-mint text-[12.5px] font-display font-bold">
                    <Sparkles className="w-4 h-4 text-mint" />
                    <span>WonderKids Shield</span>
                  </div>
                  <p className="text-[11px] text-text-secondary mt-1.5 leading-relaxed font-sans">
                    100% ad-free &amp; safely verified for happy young minds.
                  </p>
                </div>
              </div>
            </>
          )}
        </div>

        {/* Footer */}
        <div className="p-3 border-t border-border text-[10.5px] font-semibold text-text-muted text-center font-display shrink-0">
          {isExpanded || isMobileOpen ? '🌟 Safe Play Zone' : '🌟'}
        </div>
      </aside>
    </>
  );
};

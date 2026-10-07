import React from 'react';
import { Home, FolderHeart, User, ShieldCheck, Sparkles } from 'lucide-react';

export interface ChannelItem {
  name: string;
  icon?: string;
  count?: number;
}

export interface KidsSidebarProps {
  isExpanded: boolean;
  isMobileOpen: boolean;
  onCloseMobile: () => void;
  activeNav?: string; // 'home' | 'shorts' | 'watch' | 'channels' | 'you' | 'studio'
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
  // Normalize channels to { name: string }
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
          className="fixed inset-0 z-40 bg-black/70 backdrop-blur-sm lg:hidden transition-opacity"
        />
      )}

      {/* 2. Sidebar Body */}
      <aside
        className={`shrink-0 z-40 bg-[#0F0F0F] border-r border-[#222222] select-none flex flex-col transition-all duration-200 ${
          isMobileOpen
            ? 'fixed top-14 bottom-0 left-0 w-60 shadow-2xl z-50'
            : isExpanded
            ? 'w-60 hidden lg:flex'
            : 'w-[72px] hidden md:flex'
        }`}
      >
        <div className="py-2.5 px-2 flex flex-col gap-1 flex-1 overflow-y-auto">
          {/* Item 1: Home */}
          <a
            href="/"
            onClick={(e) => {
              if (onSelectNav) {
                e.preventDefault();
                handleNavClick('home', '/');
              }
            }}
            className={`flex items-center rounded-xl transition-colors ${
              isExpanded || isMobileOpen
                ? 'px-3 py-2.5 gap-4 justify-start'
                : 'flex-col py-3.5 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'home'
                ? 'bg-[#272727] text-white font-semibold'
                : 'text-[#F1F1F1] hover:bg-[#202020]'
            }`}
            title="Home"
          >
            <Home className="w-5 h-5 shrink-0" />
            <span className={isExpanded || isMobileOpen ? 'text-[14px]' : 'text-[10px]'}>
              Home
            </span>
          </a>

          {/* Item 2: Shorts (Official YouTube Shorts SVG) */}
          <a
            href="/shorts"
            onClick={(e) => {
              if (onSelectNav) {
                e.preventDefault();
                handleNavClick('shorts', '/shorts');
              }
            }}
            className={`flex items-center rounded-xl transition-colors ${
              isExpanded || isMobileOpen
                ? 'px-3 py-2.5 gap-4 justify-start'
                : 'flex-col py-3.5 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'shorts'
                ? 'bg-[#272727] text-white font-semibold'
                : 'text-[#F1F1F1] hover:bg-[#202020]'
            }`}
            title="Shorts"
          >
            <svg
              className={`w-5 h-5 shrink-0 fill-current ${
                activeNav === 'shorts' ? 'text-[#FF0000]' : 'text-white'
              }`}
              viewBox="0 0 24 24"
            >
              <path d="M17.77 10.32l-1.2-.5a3.86 3.86 0 00-.77-.24l1.43-.84a4.42 4.42 0 001.62-5.91 4.5 4.5 0 00-6.1-1.62l-7.2 4.22a4.42 4.42 0 00-1.62 5.91 4.5 4.5 0 006.1 1.62l1.2.5.77.24-1.43.84a4.42 4.42 0 00-1.62 5.91 4.5 4.5 0 006.1 1.62l7.2-4.22a4.42 4.42 0 001.62-5.91 4.5 4.5 0 00-6.1-1.62l-7.2 4.22zM10 14.5v-5l4.5 2.5-4.5 2.5z" />
            </svg>
            <span className={isExpanded || isMobileOpen ? 'text-[14px]' : 'text-[10px]'}>
              Shorts
            </span>
          </a>

          {/* Item 3: Channels */}
          <a
            href="/"
            onClick={(e) => {
              if (onSelectNav) {
                e.preventDefault();
                handleNavClick('channels', '/');
              }
            }}
            className={`flex items-center rounded-xl transition-colors ${
              isExpanded || isMobileOpen
                ? 'px-3 py-2.5 gap-4 justify-start'
                : 'flex-col py-3.5 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'channels'
                ? 'bg-[#272727] text-white font-semibold'
                : 'text-[#F1F1F1] hover:bg-[#202020]'
            }`}
            title="Channels"
          >
            <FolderHeart className="w-5 h-5 shrink-0" />
            <span className={isExpanded || isMobileOpen ? 'text-[14px]' : 'text-[10px]'}>
              Channels
            </span>
          </a>

          {/* Item 4: You / History */}
          <a
            href="/"
            onClick={(e) => {
              if (onSelectNav) {
                e.preventDefault();
                handleNavClick('you', '/');
              }
            }}
            className={`flex items-center rounded-xl transition-colors ${
              isExpanded || isMobileOpen
                ? 'px-3 py-2.5 gap-4 justify-start'
                : 'flex-col py-3.5 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'you'
                ? 'bg-[#272727] text-white font-semibold'
                : 'text-[#F1F1F1] hover:bg-[#202020]'
            }`}
            title="You"
          >
            <User className="w-5 h-5 shrink-0" />
            <span className={isExpanded || isMobileOpen ? 'text-[14px]' : 'text-[10px]'}>
              You
            </span>
          </a>

          {/* Item 5: Studio */}
          <a
            href="/studio"
            className={`flex items-center rounded-xl text-[#F1F1F1] hover:bg-[#202020] transition-colors ${
              isExpanded || isMobileOpen
                ? 'px-3 py-2.5 gap-4 justify-start'
                : 'flex-col py-3.5 px-1 gap-1.5 justify-center'
            } ${
              activeNav === 'studio' ? 'bg-[#272727] text-white font-semibold' : ''
            }`}
            title="Studio"
          >
            <ShieldCheck className="w-5 h-5 shrink-0 text-[#3EA6FF]" />
            <span className={isExpanded || isMobileOpen ? 'text-[14px]' : 'text-[10px]'}>
              Studio
            </span>
          </a>

          {/* Expanded Section: Kids Channels List */}
          {(isExpanded || isMobileOpen) && (
            <>
              {normalizedChannels.length > 0 && (
                <div className="mt-3 pt-3 border-t border-[#222222]">
                  <span className="px-3 text-[11px] font-semibold text-[#888888] uppercase tracking-wider block mb-2">
                    Subscribed Channels
                  </span>
                  {normalizedChannels.slice(0, 8).map((ch) => (
                    <div
                      key={ch.name}
                      onClick={() => handleNavClick(`channel:${ch.name}`)}
                      className="flex items-center gap-3 px-3 py-2 rounded-lg text-[13px] text-[#CCCCCC] hover:bg-[#222222] transition-colors cursor-pointer truncate"
                    >
                      <div className="w-6 h-6 rounded-full bg-gradient-to-tr from-rose-500 to-amber-500 flex items-center justify-center text-white text-[10px] font-bold shrink-0">
                        {ch.name.charAt(0)}
                      </div>
                      <span className="truncate">{ch.name}</span>
                    </div>
                  ))}
                </div>
              )}

              {/* Safe Mode Card */}
              <div className="mt-3 pt-3 border-t border-[#222222]">
                <div className="px-3 py-2 rounded-xl bg-[#161616] border border-[#262626]">
                  <div className="flex items-center gap-2 text-emerald-400 text-[12px] font-semibold">
                    <Sparkles className="w-3.5 h-3.5" />
                    Safe Kids Mode
                  </div>
                  <p className="text-[11px] text-[#888888] mt-1 leading-relaxed">
                    100% ad-free & curated for children.
                  </p>
                </div>
              </div>
            </>
          )}
        </div>

        {/* Footer */}
        <div className="p-3 border-t border-[#222222] text-[10px] text-[#717171] text-center">
          Kids Safe Mode
        </div>
      </aside>
    </>
  );
};

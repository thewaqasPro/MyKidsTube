import React from 'react';
import { Home, Flame, Heart, Tv, ChevronRight } from 'lucide-react';

export interface ChannelItem {
  name: string;
  icon?: string;
  count: number;
}

interface SidebarProps {
  isExpanded: boolean;
  isMobileOpen: boolean;
  onCloseMobile: () => void;
  activeNav: string; // 'home' | 'shorts' | 'favorites' | channel name
  onSelectNav: (nav: string) => void;
  channels: ChannelItem[];
  favoritesCount: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  isExpanded,
  isMobileOpen,
  onCloseMobile,
  activeNav,
  onSelectNav,
  channels,
  favoritesCount,
}) => {
  const mainNavItems = [
    {
      id: 'home',
      label: 'Home',
      icon: <Home className="w-5 h-5 shrink-0" />,
    },
    {
      id: 'shorts',
      label: 'Shorts',
      icon: (
        <svg className="w-5 h-5 shrink-0 fill-current" viewBox="0 0 24 24">
          <path d="M17.77 10.32l-1.2-.5a3.86 3.86 0 00-.77-.24l1.43-.84a4.42 4.42 0 001.62-5.91 4.5 4.5 0 00-6.1-1.62l-7.2 4.22a4.42 4.42 0 00-1.62 5.91 4.5 4.5 0 006.1 1.62l1.2.5.77.24-1.43.84a4.42 4.42 0 00-1.62 5.91 4.5 4.5 0 006.1 1.62l7.2-4.22a4.42 4.42 0 001.62-5.91 4.5 4.5 0 00-6.1-1.62l-7.2 4.22a4.42 4.42 0 00-1.62 5.91 4.5 4.5 0 006.1 1.62zM10 14.5v-5l4.5 2.5-4.5 2.5z" />
        </svg>
      ),
    },
    {
      id: 'favorites',
      label: 'Favorites',
      icon: <Heart className={`w-5 h-5 shrink-0 ${activeNav === 'favorites' ? 'fill-current text-[#FF0000]' : ''}`} />,
      badge: favoritesCount > 0 ? favoritesCount : undefined,
    },
  ];

  const handleNavClick = (id: string) => {
    onSelectNav(id);
    onCloseMobile();
  };

  return (
    <>
      {/* Mobile Backdrop */}
      {isMobileOpen && (
        <div
          onClick={onCloseMobile}
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden transition-opacity"
        />
      )}

      {/* Sidebar Container */}
      <aside
        className={`fixed top-14 bottom-0 left-0 z-40 bg-[#0F0F0F] border-r border-[#222222] transition-all duration-200 select-none flex flex-col ${
          // Mobile drawer classes
          isMobileOpen
            ? 'translate-x-0 w-64 shadow-2xl'
            : '-translate-x-full lg:translate-x-0'
        } ${
          // Desktop expanded vs collapsed
          isExpanded ? 'lg:w-60' : 'lg:w-[72px]'
        }`}
      >
        <div className="flex-1 overflow-y-auto no-scrollbar py-3 px-2 flex flex-col gap-1">
          {/* Main Navigation Items */}
          {mainNavItems.map((item) => {
            const isActive = activeNav === item.id;
            return (
              <button
                key={item.id}
                onClick={() => handleNavClick(item.id)}
                className={`w-full flex items-center rounded-xl transition-colors ${
                  isExpanded || isMobileOpen
                    ? 'px-3 py-2.5 gap-4 justify-start'
                    : 'flex-col py-3 px-1 gap-1.5 justify-center'
                } ${
                  isActive
                    ? 'bg-[#272727] text-white font-semibold'
                    : 'text-[#F1F1F1] hover:bg-[#202020]'
                }`}
                title={item.label}
              >
                <div className={isActive ? 'text-[#FF0000]' : 'text-white'}>
                  {item.icon}
                </div>

                <span
                  className={`truncate ${
                    isExpanded || isMobileOpen
                      ? 'text-[14px] flex-1 text-left'
                      : 'text-[10px] text-center font-normal'
                  }`}
                >
                  {item.label}
                </span>

                {(isExpanded || isMobileOpen) && item.badge !== undefined && (
                  <span className="px-1.5 py-0.5 rounded-full text-[11px] font-bold bg-[#FF0000]/20 text-[#FF4E45] border border-[#FF0000]/30">
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}

          {/* Expanded Channels Section */}
          {(isExpanded || isMobileOpen) && (
            <>
              <div className="my-3 border-t border-[#272727]" />

              <div className="px-3 py-1 flex items-center justify-between text-[#AAAAAA]">
                <span className="text-[12px] font-semibold tracking-wider uppercase">
                  Channels
                </span>
                <span className="text-[11px] font-medium text-[#717171]">
                  {channels.length}
                </span>
              </div>

              <div className="flex flex-col gap-0.5 mt-1">
                {channels.map((ch) => {
                  const isChActive = activeNav === `channel:${ch.name}`;
                  return (
                    <button
                      key={ch.name}
                      onClick={() => handleNavClick(`channel:${ch.name}`)}
                      className={`w-full flex items-center gap-3 px-3 py-2 rounded-xl text-left transition-colors group ${
                        isChActive
                          ? 'bg-[#272727] text-white font-semibold'
                          : 'text-[#E1E1E1] hover:bg-[#202020]'
                      }`}
                      title={ch.name}
                    >
                      {/* Channel Avatar */}
                      <div className="relative w-6 h-6 rounded-full overflow-hidden shrink-0 bg-[#2a2a2a] border border-[#333333]">
                        {ch.icon ? (
                          <img
                            src={ch.icon}
                            alt={ch.name}
                            loading="lazy"
                            className="w-full h-full object-cover"
                            onError={(e) => {
                              // Fallback to text initial
                              (e.target as HTMLElement).style.display = 'none';
                            }}
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center bg-gradient-to-tr from-rose-600 to-amber-500 text-[10px] font-bold text-white">
                            {ch.name.charAt(0).toUpperCase()}
                          </div>
                        )}
                      </div>

                      {/* Channel Title */}
                      <span className="text-[13px] truncate flex-1 leading-snug">
                        {ch.name}
                      </span>

                      {/* Video count pill */}
                      <span className="text-[11px] text-[#717171] group-hover:text-[#AAAAAA]">
                        {ch.count}
                      </span>
                    </button>
                  );
                })}
              </div>

              {/* Safe Content Trust Notice */}
              <div className="mt-auto pt-6 px-3 pb-2 text-[11px] text-[#717171] leading-relaxed">
                <div className="flex items-center gap-1.5 text-[#00E676] font-medium mb-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#00E676] animate-pulse" />
                  <span>Curated & Safe</span>
                </div>
                Zero adult content, strict parental gatekeeping enabled.
              </div>
            </>
          )}

          {/* Mini Collapsed Channels Button */}
          {!isExpanded && !isMobileOpen && (
            <div className="pt-2 flex flex-col items-center">
              <div className="w-8 border-t border-[#272727] mb-2" />
              <button
                onClick={() => onSelectNav('home')}
                className="w-full flex flex-col items-center py-2 text-[#AAAAAA] hover:text-white"
                title="Channels"
              >
                <Tv className="w-5 h-5 mb-1" />
                <span className="text-[9px]">Channels</span>
              </button>
            </div>
          )}
        </div>
      </aside>
    </>
  );
};

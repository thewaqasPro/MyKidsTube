import React from 'react';
import { 
  LayoutDashboard, 
  Film, 
  PlusCircle, 
  Tablet, 
  BarChart3, 
  KeyRound, 
  Home, 
  ShieldCheck,
  ChevronRight
} from 'lucide-react';

export interface StudioSidebarProps {
  activeTab?: string; // 'dashboard' | 'videos' | 'upload' | 'devices' | 'analytics' | 'settings'
  onSelectTab?: (tab: string) => void;
  isExpanded?: boolean;
  isMobileOpen?: boolean;
  onCloseMobile?: () => void;
}

export const StudioSidebar: React.FC<StudioSidebarProps> = ({
  activeTab = 'dashboard',
  onSelectTab,
  isExpanded = true,
  isMobileOpen = false,
  onCloseMobile,
}) => {
  const navItems = [
    {
      id: 'dashboard',
      label: 'Dashboard',
      icon: <LayoutDashboard className="w-5 h-5 shrink-0" />,
      href: '/studio',
    },
    {
      id: 'videos',
      label: 'Content & Videos',
      icon: <Film className="w-5 h-5 shrink-0" />,
      href: '/studio#videos',
    },
    {
      id: 'upload',
      label: 'Wishlist & Add',
      icon: <PlusCircle className="w-5 h-5 shrink-0" />,
      href: '/upload',
    },
    {
      id: 'devices',
      label: 'Tablet Devices',
      icon: <Tablet className="w-5 h-5 shrink-0" />,
      href: '/studio#devices',
    },
    {
      id: 'analytics',
      label: 'Watch Analytics',
      icon: <BarChart3 className="w-5 h-5 shrink-0" />,
      href: '/studio#analytics',
    },
    {
      id: 'settings',
      label: 'PIN & Security',
      icon: <KeyRound className="w-5 h-5 shrink-0" />,
      href: '/studio#settings',
    },
  ];

  const handleItemClick = (id: string, href: string) => {
    if (onSelectTab) {
      onSelectTab(id);
    }
    if (onCloseMobile) {
      onCloseMobile();
    }
    if (typeof window !== 'undefined' && window.location.pathname !== href.split('#')[0]) {
      window.location.href = href;
    }
  };

  return (
    <>
      {/* Mobile Backdrop */}
      {isMobileOpen && (
        <div
          onClick={onCloseMobile}
          className="fixed inset-0 z-40 bg-black/70 backdrop-blur-sm lg:hidden transition-opacity"
        />
      )}

      {/* Studio Sidebar Container */}
      <aside
        className={`shrink-0 z-40 bg-[#0F0F0F] border-r border-[#222222] select-none flex flex-col transition-all duration-200 ${
          isMobileOpen
            ? 'fixed top-14 bottom-0 left-0 w-64 shadow-2xl z-50'
            : isExpanded
            ? 'w-64 hidden md:flex'
            : 'w-[72px] hidden md:flex'
        }`}
      >
        {/* Parent Admin Channel Header */}
        <div className="p-4 border-b border-[#222222] flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center text-white text-[15px] font-bold shadow-md shrink-0 border border-blue-400/30">
            <ShieldCheck className="w-5 h-5" />
          </div>
          {(isExpanded || isMobileOpen) && (
            <div className="flex flex-col min-w-0">
              <span className="text-[13px] font-semibold text-white truncate">
                Parent Admin
              </span>
              <span className="text-[11px] text-[#888888] truncate">
                My Family Controls
              </span>
            </div>
          )}
        </div>

        {/* Sidebar Nav Links */}
        <div className="py-3 px-2 flex flex-col gap-1 flex-1 overflow-y-auto">
          {navItems.map((item) => {
            const isActive = activeTab === item.id;
            return (
              <a
                key={item.id}
                href={item.href}
                onClick={(e) => {
                  if (onSelectTab) {
                    e.preventDefault();
                    handleItemClick(item.id, item.href);
                  }
                }}
                className={`flex items-center rounded-xl transition-colors ${
                  isExpanded || isMobileOpen
                    ? 'px-3 py-2.5 gap-3.5 justify-start'
                    : 'flex-col py-3 px-1 gap-1.5 justify-center'
                } ${
                  isActive
                    ? 'bg-[#272727] text-white font-semibold'
                    : 'text-[#AAAAAA] hover:text-white hover:bg-[#1C1C1C]'
                }`}
                title={item.label}
              >
                <div className={isActive ? 'text-[#3EA6FF]' : 'text-[#AAAAAA]'}>
                  {item.icon}
                </div>
                {(isExpanded || isMobileOpen) && (
                  <span className="text-[13px]">{item.label}</span>
                )}
              </a>
            );
          })}
        </div>

        {/* Bottom Link: Return to Kids App */}
        <div className="p-3 border-t border-[#222222]">
          <a
            href="/"
            className="flex items-center justify-center gap-2 w-full py-2 px-3 rounded-xl bg-[#1C1C1C] hover:bg-[#252525] text-white text-[12px] font-medium transition-colors border border-[#2D2D2D]"
          >
            <Home className="w-4 h-4 text-[#FF0000]" />
            {(isExpanded || isMobileOpen) && <span>Exit to KidsTube</span>}
          </a>
        </div>
      </aside>
    </>
  );
};

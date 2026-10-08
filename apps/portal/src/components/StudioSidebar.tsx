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
        className={`shrink-0 z-40 bg-[#0B0F19] border-r-2 border-[#1E294B] select-none flex flex-col transition-all duration-200 ${
          isMobileOpen
            ? 'fixed top-16 bottom-0 left-0 w-64 shadow-2xl z-50 overflow-y-auto custom-scrollbar'
            : isExpanded
            ? 'sticky top-16 h-[calc(100vh-4rem)] self-start w-64 hidden md:flex overflow-hidden'
            : 'sticky top-16 h-[calc(100vh-4rem)] self-start w-[76px] hidden md:flex overflow-hidden'
        }`}
      >
        {/* Parent Admin Channel Header */}
        <div className="p-4 border-b-2 border-[#1E294B] flex items-center gap-3 shrink-0">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-[#38BDF8] to-[#A855F7] flex items-center justify-center text-white text-base font-bold shadow-md shrink-0 border-2 border-white/20">
            <ShieldCheck className="w-5 h-5 text-white" />
          </div>
          {(isExpanded || isMobileOpen) && (
            <div className="flex flex-col min-w-0">
              <span className="font-display font-black text-sm text-white truncate">
                Parent Admin
              </span>
              <span className="text-xs text-[#94A3B8] font-semibold truncate">
                Family Security Hub
              </span>
            </div>
          )}
        </div>

        {/* Sidebar Nav Links */}
        <div className="py-4 px-3 flex flex-col gap-1.5 flex-1 min-h-0 overflow-y-auto custom-scrollbar">
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
                className={`flex items-center rounded-2xl transition-all duration-200 no-underline cursor-pointer ${
                  isExpanded || isMobileOpen
                    ? 'px-3.5 py-3 gap-3.5 justify-start'
                    : 'flex-col py-3 px-1 gap-1.5 justify-center'
                } ${
                  isActive
                    ? 'bg-[#151D33] text-white font-black border-2 border-[#1E294B] shadow-sm'
                    : 'text-[#94A3B8] hover:text-white hover:bg-[#151D33]/60'
                }`}
                title={item.label}
              >
                <div className={isActive ? 'text-[#38BDF8]' : 'text-[#64748B]'}>
                  {item.icon}
                </div>
                {(isExpanded || isMobileOpen) && (
                  <span className="text-xs font-bold tracking-wide">{item.label}</span>
                )}
              </a>
            );
          })}
        </div>

        {/* Bottom Link: Return to Kids App */}
        <div className="p-3 border-t-2 border-[#1E294B] shrink-0">
          <a
            href="/"
            className="flex items-center justify-center gap-2 w-full py-2.5 px-3 rounded-2xl bg-[#151D33] hover:bg-[#1E294B] text-white text-xs font-bold transition-all border border-[#1E294B] no-underline active:scale-95"
          >
            <Home className="w-4 h-4 text-[#FF5E62]" />
            {(isExpanded || isMobileOpen) && <span>Exit to KidsTube</span>}
          </a>
        </div>
      </aside>
    </>
  );
};

import React, { useState, useEffect, useMemo } from 'react';
import type { Video, Category, ChildProfile } from '../types/video';
import { 
  Play, 
  Upload, 
  Trash2, 
  HardDrive, 
  Clock, 
  Eye, 
  Search, 
  Filter, 
  CheckCircle, 
  Sparkles,
  RefreshCw,
  FolderDown,
  Tablet,
  KeyRound,
  ShieldCheck,
  ChevronRight,
  Tv,
  Film
} from 'lucide-react';
import { getThumbnailUrl, getYoutubeId, isSelfHosted, isVideoShort } from '../lib/constants';
import { StudioTopBar } from './StudioTopBar';
import { StudioSidebar } from './StudioSidebar';

interface StudioDashboardProps {
  initialVideos: Video[];
  initialCategories: Category[];
  initialProfiles: ChildProfile[];
  initialStats: any;
}

export const StudioDashboard: React.FC<StudioDashboardProps> = ({
  initialVideos,
  initialCategories,
  initialProfiles,
  initialStats,
}) => {
  const [videos, setVideos] = useState<Video[]>(initialVideos);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'ready' | 'pending'>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [isDeletingId, setIsDeletingId] = useState<string | null>(null);

  // Studio Shell State
  const [activeTab, setActiveTab] = useState<string>('dashboard');
  const [isSidebarExpanded, setIsSidebarExpanded] = useState(true);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);

  // Sync hash with active tab
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const hash = window.location.hash.replace('#', '');
      if (hash && ['dashboard', 'videos', 'devices', 'analytics', 'settings'].includes(hash)) {
        setActiveTab(hash);
      }
    }
  }, []);

  const handleSelectTab = (tab: string) => {
    setActiveTab(tab);
    if (typeof window !== 'undefined') {
      window.location.hash = tab;
    }
  };

  // Filtered list
  const filteredVideos = useMemo(() => {
    return videos.filter((v) => {
      const matchesSearch = 
        v.title.toLowerCase().includes(search.toLowerCase()) ||
        (v.channel_name && v.channel_name.toLowerCase().includes(search.toLowerCase()));

      const matchesCategory = categoryFilter === 'all' || v.category_id === categoryFilter;

      const isReady = isSelfHosted(v);
      const matchesStatus = 
        statusFilter === 'all' ||
        (statusFilter === 'ready' && isReady) ||
        (statusFilter === 'pending' && !isReady);

      return matchesSearch && matchesCategory && matchesStatus;
    });
  }, [videos, search, statusFilter, categoryFilter]);

  // Aggregate stats
  const totalCount = videos.length;
  const readyCount = videos.filter((v) => isSelfHosted(v)).length;
  const pendingCount = totalCount - readyCount;
  const totalViews = videos.reduce((acc, v) => acc + (v.views || 0), 0);
  const totalWatchSec = videos.reduce((acc, v) => acc + (v.watch_seconds || 0), 0);
  const totalWatchHours = (totalWatchSec / 3600).toFixed(1);

  // Handle Video Deletion
  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to remove this video from your kids catalog?')) return;
    setIsDeletingId(id);
    try {
      const res = await fetch(`/api/studio/videos?id=${id}`, { method: 'DELETE' });
      if (res.ok) {
        setVideos((prev) => prev.filter((v) => v.id !== id));
      }
    } catch (e) {
      alert('Failed to delete video');
    } finally {
      setIsDeletingId(null);
    }
  };

  // Download links.txt
  const handleExportLinks = () => {
    window.location.href = '/api/queue/pending?format=txt';
  };

  return (
    <div className="min-h-screen bg-[#0F0F0F] text-[#F1F1F1] flex flex-col font-sans">
      {/* 1. Dedicated Studio Top Bar */}
      <StudioTopBar
        searchQuery={search}
        onSearchChange={setSearch}
        onToggleSidebar={() => {
          if (window.innerWidth < 1024) {
            setIsMobileSidebarOpen((prev) => !prev);
          } else {
            setIsSidebarExpanded((prev) => !prev);
          }
        }}
      />

      {/* 2. Main Flex Layout: Studio Sidebar + Studio Content */}
      <div className="flex flex-1 relative overflow-x-hidden">
        {/* Dedicated Studio Sidebar with all links on the side */}
        <StudioSidebar
          activeTab={activeTab}
          onSelectTab={handleSelectTab}
          isExpanded={isSidebarExpanded}
          isMobileOpen={isMobileSidebarOpen}
          onCloseMobile={() => setIsMobileSidebarOpen(false)}
        />

        {/* 3. Main Studio Workspace */}
        <main className="flex-1 min-w-0 p-4 sm:p-6 md:p-8 space-y-6">
          
          {/* TAB 1: DASHBOARD OVERVIEW */}
          {(activeTab === 'dashboard' || activeTab === 'analytics') && (
            <div className="space-y-6">
              <div>
                <h1 className="text-[22px] font-bold text-white tracking-tight">Studio Dashboard</h1>
                <p className="text-[13px] text-[#888888]">Overview of catalog storage, streaming modes, and kid viewing metrics.</p>
              </div>

              {/* Analytics Metric Cards */}
              <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                {/* Total Videos Card */}
                <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl flex flex-col justify-between shadow-sm">
                  <div className="flex items-center justify-between text-[#888888]">
                    <span className="text-[12px] font-semibold uppercase tracking-wider">Catalog Inventory</span>
                    <Film className="w-4 h-4 text-[#FF0000]" />
                  </div>
                  <div className="mt-4">
                    <span className="text-[28px] font-extrabold text-white">{totalCount}</span>
                    <span className="text-[13px] text-[#AAAAAA] ml-1.5">Videos</span>
                  </div>
                  <div className="mt-2 text-[12px] flex items-center gap-2 font-medium">
                    <span className="text-emerald-400">● {readyCount} Self-Hosted</span>
                    <span className="text-amber-400">● {pendingCount} Embed</span>
                  </div>
                </div>

                {/* Watch Hours Card */}
                <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl flex flex-col justify-between shadow-sm">
                  <div className="flex items-center justify-between text-[#888888]">
                    <span className="text-[12px] font-semibold uppercase tracking-wider">Watch Time</span>
                    <Clock className="w-4 h-4 text-[#3EA6FF]" />
                  </div>
                  <div className="mt-4">
                    <span className="text-[28px] font-extrabold text-white">{totalWatchHours}</span>
                    <span className="text-[13px] text-[#AAAAAA] ml-1.5">Hours</span>
                  </div>
                  <div className="mt-2 text-[12px] text-[#888888]">
                    Accumulated across kid tablets
                  </div>
                </div>

                {/* Total Views Card */}
                <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl flex flex-col justify-between shadow-sm">
                  <div className="flex items-center justify-between text-[#888888]">
                    <span className="text-[12px] font-semibold uppercase tracking-wider">Total Views</span>
                    <Eye className="w-4 h-4 text-emerald-400" />
                  </div>
                  <div className="mt-4">
                    <span className="text-[28px] font-extrabold text-white">{totalViews}</span>
                    <span className="text-[13px] text-[#AAAAAA] ml-1.5">Plays</span>
                  </div>
                  <div className="mt-2 text-[12px] text-[#888888]">
                    100% ad-free & safe
                  </div>
                </div>

                {/* VPS Storage Card */}
                <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl flex flex-col justify-between shadow-sm">
                  <div className="flex items-center justify-between text-[#888888]">
                    <span className="text-[12px] font-semibold uppercase tracking-wider">VPS Media Storage</span>
                    <HardDrive className="w-4 h-4 text-purple-400" />
                  </div>
                  <div className="mt-4">
                    <span className="text-[28px] font-extrabold text-white">80 GB</span>
                    <span className="text-[13px] text-[#AAAAAA] ml-1.5">Disk</span>
                  </div>
                  <div className="mt-2 text-[12px] text-emerald-400 font-medium flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                    <span>Nginx Direct Streamer Active</span>
                  </div>
                </div>
              </section>

              {/* HandBrake Sync Pipeline Helper */}
              <section className="p-6 bg-gradient-to-r from-[#1C1C1C] to-[#161616] border border-[#2A2A2A] rounded-2xl flex flex-col lg:flex-row items-center justify-between gap-6 shadow-sm">
                <div className="space-y-1.5 text-center lg:text-left">
                  <div className="flex items-center justify-center lg:justify-start gap-2">
                    <Sparkles className="w-4 h-4 text-[#FF0000]" />
                    <span className="text-[14px] font-bold text-white uppercase tracking-wider">
                      HandBrake Batch Encoding Pipeline
                    </span>
                  </div>
                  <p className="text-[13px] text-[#AAAAAA] max-w-2xl leading-relaxed">
                    Export your pending wishlist to your Mac, batch encode with HandBrake (<span className="text-white font-mono">Fast 720p30, RF 24</span>), and upload to your 80GB VPS storage for 70% smaller file sizes.
                  </p>
                </div>

                <div className="flex flex-wrap items-center gap-3">
                  <button
                    onClick={handleExportLinks}
                    className="flex items-center gap-2 px-4 py-2.5 bg-[#FF0000] hover:bg-[#CC0000] text-white text-[13px] font-semibold rounded-xl shadow-md transition-colors cursor-pointer"
                  >
                    <FolderDown className="w-4 h-4" />
                    <span>1-Click Export links.txt ({pendingCount})</span>
                  </button>

                  <a
                    href="/upload"
                    className="flex items-center gap-2 px-4 py-2.5 bg-[#252525] hover:bg-[#303030] text-[#DDDDDD] hover:text-white text-[13px] font-medium rounded-xl border border-[#333333] transition-colors"
                  >
                    <Upload className="w-4 h-4" />
                    <span>Dropzone</span>
                  </a>
                </div>
              </section>
            </div>
          )}

          {/* TAB 2: VIDEOS & CONTENT MANAGEMENT */}
          {(activeTab === 'videos' || activeTab === 'dashboard') && (
            <section className="space-y-4 pt-2">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <h2 className="text-[18px] font-bold text-white tracking-tight">Channel Content</h2>
                  <p className="text-[12px] text-[#888888]">Manage catalog videos, verify MP4 storage, or remove content.</p>
                </div>

                {/* Filter Controls */}
                <div className="flex flex-wrap items-center gap-2.5">
                  {/* Status Filter */}
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value as any)}
                    className="h-9 px-3 bg-[#1C1C1C] border border-[#2E2E2E] rounded-xl text-[12px] text-[#DDDDDD] outline-none cursor-pointer"
                  >
                    <option value="all">All Playback ({totalCount})</option>
                    <option value="ready">Self-Hosted MP4 ({readyCount})</option>
                    <option value="pending">YouTube Embed ({pendingCount})</option>
                  </select>

                  {/* Category Filter */}
                  <select
                    value={categoryFilter}
                    onChange={(e) => setCategoryFilter(e.target.value)}
                    className="h-9 px-3 bg-[#1C1C1C] border border-[#2E2E2E] rounded-xl text-[12px] text-[#DDDDDD] outline-none cursor-pointer"
                  >
                    <option value="all">All Categories</option>
                    {initialCategories.map((c) => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>

                  <button
                    onClick={() => {
                      setSearch('');
                      setStatusFilter('all');
                      setCategoryFilter('all');
                    }}
                    className="h-9 px-3 bg-[#1C1C1C] hover:bg-[#252525] border border-[#2E2E2E] rounded-xl text-[12px] text-[#AAAAAA] hover:text-white transition-colors cursor-pointer"
                    title="Reset filters"
                  >
                    Reset
                  </button>
                </div>
              </div>

              {/* Videos Table */}
              <div className="bg-[#141414] border border-[#242424] rounded-2xl overflow-hidden shadow-sm">
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="border-b border-[#242424] bg-[#181818]/70 text-[11px] font-semibold text-[#888888] uppercase tracking-wider">
                        <th className="py-3 px-4">Video</th>
                        <th className="py-3 px-4 hidden md:table-cell">Playback Mode</th>
                        <th className="py-3 px-4 hidden sm:table-cell">Category</th>
                        <th className="py-3 px-4 text-center hidden lg:table-cell">Views</th>
                        <th className="py-3 px-4 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#202020] text-[13px]">
                      {filteredVideos.length === 0 ? (
                        <tr>
                          <td colSpan={5} className="py-8 text-center text-[#777777]">
                            No videos matched your filters.
                          </td>
                        </tr>
                      ) : (
                        filteredVideos.map((v) => {
                          const isReady = isSelfHosted(v);
                          const thumb = getThumbnailUrl(v);
                          const cleanTitle = v.title.includes('•') ? v.title.split('•').slice(1).join('•').trim() : v.title;
                          const cleanChannel = v.channel_name || (v.title.includes('•') ? v.title.split('•')[0].trim() : 'KidsTube');

                          return (
                            <tr key={v.id} className="hover:bg-[#1A1A1A] transition-colors group">
                              {/* Video Cell */}
                              <td className="py-3 px-4">
                                <div className="flex items-center gap-3 min-w-[240px]">
                                  <div className="relative w-20 aspect-video rounded-lg overflow-hidden bg-[#222222] shrink-0 border border-[#2A2A2A]">
                                    <img src={thumb} alt={cleanTitle} className="w-full h-full object-cover" />
                                    <div className="absolute bottom-0.5 right-0.5 px-1 rounded bg-black/80 text-[9px] font-mono text-white">
                                      {v.duration_formatted || '03:00'}
                                    </div>
                                  </div>
                                  <div className="min-w-0">
                                    <a
                                      href={isVideoShort(v) ? `/shorts?v=${v.id}` : `/watch/${v.id}`}
                                      className="font-medium text-white hover:text-[#3EA6FF] line-clamp-1 transition-colors"
                                    >
                                      {cleanTitle}
                                    </a>
                                    <span className="text-[11px] text-[#888888] block truncate mt-0.5">
                                      {cleanChannel}
                                    </span>
                                  </div>
                                </div>
                              </td>

                              {/* Playback Mode */}
                              <td className="py-3 px-4 hidden md:table-cell">
                                {isReady ? (
                                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-emerald-950/70 text-emerald-400 border border-emerald-800">
                                    <CheckCircle className="w-3.5 h-3.5" />
                                    <span>Self-Hosted MP4</span>
                                  </span>
                                ) : (
                                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-amber-950/70 text-amber-400 border border-amber-800">
                                    <Sparkles className="w-3.5 h-3.5" />
                                    <span>YouTube Embed</span>
                                  </span>
                                )}
                              </td>

                              {/* Category */}
                              <td className="py-3 px-4 hidden sm:table-cell text-[#AAAAAA] capitalize">
                                {v.category_id}
                              </td>

                              {/* Views */}
                              <td className="py-3 px-4 text-center font-mono text-[#DDDDDD] hidden lg:table-cell">
                                {v.views || 0}
                              </td>

                              {/* Actions */}
                              <td className="py-3 px-4 text-right">
                                <div className="flex items-center justify-end gap-1.5">
                                  <a
                                    href={isVideoShort(v) ? `/shorts?v=${v.id}` : `/watch/${v.id}`}
                                    className="p-2 rounded-lg bg-[#202020] hover:bg-[#2A2A2A] text-[#DDDDDD] hover:text-white transition-colors"
                                    title={isVideoShort(v) ? "Watch Short" : "Watch Video"}
                                  >
                                    <Play className="w-3.5 h-3.5 fill-current" />
                                  </a>

                                  <button
                                    onClick={() => handleDelete(v.id)}
                                    disabled={isDeletingId === v.id}
                                    className="p-2 rounded-lg bg-[#202020] hover:bg-red-950 text-[#DDDDDD] hover:text-red-400 transition-colors cursor-pointer disabled:opacity-50"
                                    title="Delete from Catalog"
                                  >
                                    <Trash2 className="w-3.5 h-3.5" />
                                  </button>
                                </div>
                              </td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </section>
          )}

          {/* TAB 3: TABLET DEVICES */}
          {activeTab === 'devices' && (
            <div className="space-y-6">
              <div>
                <h1 className="text-[22px] font-bold text-white tracking-tight">Kid Tablet Devices</h1>
                <p className="text-[13px] text-[#888888]">Pair and manage mobile tablet apps running MyKidsTube Flutter client.</p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-6 bg-[#181818] border border-[#262626] rounded-2xl space-y-4">
                  <div className="flex items-center gap-3">
                    <div className="p-2.5 rounded-xl bg-blue-500/10 text-[#3EA6FF]">
                      <Tablet className="w-6 h-6" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-white">Kids Tablet (iPad / Fire HD)</h3>
                      <p className="text-[12px] text-[#888888]">Status: Paired & Active</p>
                    </div>
                  </div>
                  <div className="p-4 rounded-xl bg-[#121212] border border-[#222222] text-[12px] space-y-2">
                    <div className="flex justify-between">
                      <span className="text-[#888888]">Profile Assigned:</span>
                      <span className="text-white font-medium">All Kids</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-[#888888]">Device Token:</span>
                      <span className="font-mono text-emerald-400">tok_bd677b0dc...</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 4: PIN & SETTINGS */}
          {activeTab === 'settings' && (
            <div className="space-y-6">
              <div>
                <h1 className="text-[22px] font-bold text-white tracking-tight">Parent Security & PIN</h1>
                <p className="text-[13px] text-[#888888]">Manage parental controls and 4-digit PIN authentication.</p>
              </div>

              <div className="max-w-md p-6 bg-[#181818] border border-[#262626] rounded-2xl space-y-4">
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-emerald-500/10 text-emerald-400">
                    <KeyRound className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-white">Parent PIN</h3>
                    <p className="text-[12px] text-[#888888]">Default: 1234</p>
                  </div>
                </div>
                <p className="text-[12px] text-[#AAAAAA] leading-relaxed">
                  Your 4-digit PIN secures the YouTube Studio, download queue, and video deletion from children on tablets.
                </p>
              </div>
            </div>
          )}

        </main>
      </div>
    </div>
  );
};

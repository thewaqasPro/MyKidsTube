import React from 'react';
import { Film, HardDrive, Sparkles, FolderDown, Upload, CheckCircle, ArrowRight } from 'lucide-react';

export interface StudioOverviewTabProps {
  totalVideos: number;
  readyCount: number;
  pendingCount: number;
  storageUsedBytes: number;
  storageTotalGb?: number;
  onExportLinks: () => void;
  onNavigateToVideos?: () => void;
}

export const StudioOverviewTab: React.FC<StudioOverviewTabProps> = ({
  totalVideos,
  readyCount,
  pendingCount,
  storageUsedBytes,
  storageTotalGb = 80,
  onExportLinks,
  onNavigateToVideos,
}) => {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-[22px] font-bold text-white tracking-tight">Studio Dashboard</h1>
        <p className="text-[13px] text-[#888888]">
          Overview of catalog storage, streaming modes, and kid viewing metrics.
        </p>
      </div>

      {/* Analytics Metric Cards */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Videos Card */}
        <div className="p-5 bg-[#151D33] border-2 border-[#1E294B] rounded-3xl flex flex-col justify-between shadow-lg">
          <div className="flex items-center justify-between text-[#94A3B8]">
            <span className="text-xs font-bold uppercase tracking-wider">Catalog Inventory</span>
            <Film className="w-4 h-4 text-[#FF5E62]" />
          </div>
          <div className="mt-4">
            <span className="text-3xl font-display font-black text-white">{totalVideos}</span>
            <span className="text-xs text-[#94A3B8] ml-2 font-medium">Videos</span>
          </div>
          {onNavigateToVideos && (
            <button
              onClick={onNavigateToVideos}
              className="mt-3 text-xs text-[#38BDF8] hover:underline flex items-center gap-1 font-bold cursor-pointer"
            >
              <span>Manage catalog</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          )}
        </div>

        {/* Self-Hosted Card */}
        <div className="p-5 bg-[#151D33] border-2 border-[#1E294B] rounded-3xl flex flex-col justify-between shadow-lg">
          <div className="flex items-center justify-between text-[#94A3B8]">
            <span className="text-xs font-bold uppercase tracking-wider">Self-Hosted MP4</span>
            <CheckCircle className="w-4 h-4 text-[#10B981]" />
          </div>
          <div className="mt-4">
            <span className="text-3xl font-display font-black text-white">{readyCount}</span>
            <span className="text-xs text-[#94A3B8] ml-2 font-medium">Ready for Tablet</span>
          </div>
          <div className="mt-3 text-xs text-[#94A3B8] font-medium">
            Direct Nginx offline-ready storage
          </div>
        </div>

        {/* Wishlist Pending Card */}
        <div className="p-5 bg-[#151D33] border-2 border-[#1E294B] rounded-3xl flex flex-col justify-between shadow-lg">
          <div className="flex items-center justify-between text-[#94A3B8]">
            <span className="text-xs font-bold uppercase tracking-wider">YouTube Wishlist</span>
            <Sparkles className="w-4 h-4 text-[#FFB300]" />
          </div>
          <div className="mt-4">
            <span className="text-3xl font-display font-black text-white">{pendingCount}</span>
            <span className="text-xs text-[#94A3B8] ml-2 font-medium">Awaiting Download</span>
          </div>
          <div className="mt-3 text-xs text-[#FFB300] font-bold">
            Streaming via safe embed iframe
          </div>
        </div>

        {/* VPS Disk Storage Card */}
        <div className="p-5 bg-[#151D33] border-2 border-[#1E294B] rounded-3xl flex flex-col justify-between shadow-lg">
          <div className="flex items-center justify-between text-[#94A3B8]">
            <span className="text-xs font-bold uppercase tracking-wider">VPS Disk Usage</span>
            <HardDrive className="w-4 h-4 text-[#38BDF8]" />
          </div>
          <div className="mt-4">
            <span className="text-3xl font-display font-black text-white">
              {(storageUsedBytes / (1024 * 1024 * 1024)).toFixed(2)} GB
            </span>
            <span className="text-xs text-[#94A3B8] ml-2 font-medium">/ {storageTotalGb} GB</span>
          </div>
          <div className="mt-3 text-xs text-[#10B981] font-bold flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-[#10B981] animate-pulse" />
            <span>Nginx Direct Streamer Active</span>
          </div>
        </div>
      </section>

      {/* HandBrake Sync Pipeline Helper */}
      <section className="p-6 sm:p-7 bg-gradient-to-r from-[#151D33] to-[#1E294B] border-2 border-[#1E294B] rounded-[32px] flex flex-col lg:flex-row items-center justify-between gap-6 shadow-xl">
        <div className="space-y-1.5 text-center lg:text-left">
          <div className="flex items-center justify-center lg:justify-start gap-2">
            <Sparkles className="w-4 h-4 text-[#FFB300]" />
            <span className="text-sm font-display font-black text-white tracking-wide">
              HandBrake Batch Encoding Pipeline
            </span>
          </div>
          <p className="text-xs text-[#94A3B8] max-w-2xl leading-relaxed font-medium">
            Export your pending wishlist to your Mac, batch encode with HandBrake (
            <span className="text-white font-mono">Fast 720p30, RF 24</span>), and upload to your {storageTotalGb}GB
            VPS storage for 70% smaller file sizes.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={onExportLinks}
            className="flex items-center gap-2 px-5 py-3 bg-gradient-to-r from-[#FF5E62] to-[#FF8E53] hover:from-[#FF8E53] hover:to-[#FF5E62] text-white text-xs font-display font-black rounded-2xl shadow-lg shadow-[#FF5E62]/20 transition-all cursor-pointer active:scale-95 border border-white/10"
          >
            <FolderDown className="w-4 h-4" />
            <span>1-Click Export links.txt ({pendingCount})</span>
          </button>

          <a
            href="/upload"
            className="flex items-center gap-2 px-4 py-3 bg-[#151D33] hover:bg-[#1E294B] text-[#94A3B8] hover:text-white text-xs font-bold rounded-2xl border-2 border-[#1E294B] transition-colors no-underline active:scale-95"
          >
            <Upload className="w-4 h-4 text-[#38BDF8]" />
            <span>Dropzone</span>
          </a>
        </div>
      </section>
    </div>
  );
};

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
        <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between text-[#888888]">
            <span className="text-[12px] font-semibold uppercase tracking-wider">Catalog Inventory</span>
            <Film className="w-4 h-4 text-[#FF0000]" />
          </div>
          <div className="mt-4">
            <span className="text-[28px] font-extrabold text-white">{totalVideos}</span>
            <span className="text-[13px] text-[#AAAAAA] ml-1.5">Videos</span>
          </div>
          {onNavigateToVideos && (
            <button
              onClick={onNavigateToVideos}
              className="mt-3 text-[12px] text-[#3EA6FF] hover:underline flex items-center gap-1 font-medium cursor-pointer"
            >
              <span>Manage catalog</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          )}
        </div>

        {/* Self-Hosted Card */}
        <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between text-[#888888]">
            <span className="text-[12px] font-semibold uppercase tracking-wider">Self-Hosted MP4</span>
            <CheckCircle className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="mt-4">
            <span className="text-[28px] font-extrabold text-white">{readyCount}</span>
            <span className="text-[13px] text-[#AAAAAA] ml-1.5">Ready for Tablet</span>
          </div>
          <div className="mt-3 text-[12px] text-[#888888]">
            Direct Nginx offline-ready storage
          </div>
        </div>

        {/* Wishlist Pending Card */}
        <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between text-[#888888]">
            <span className="text-[12px] font-semibold uppercase tracking-wider">YouTube Wishlist</span>
            <Sparkles className="w-4 h-4 text-amber-500" />
          </div>
          <div className="mt-4">
            <span className="text-[28px] font-extrabold text-white">{pendingCount}</span>
            <span className="text-[13px] text-[#AAAAAA] ml-1.5">Awaiting Download</span>
          </div>
          <div className="mt-3 text-[12px] text-amber-400 font-medium">
            Streaming via safe embed iframe
          </div>
        </div>

        {/* VPS Disk Storage Card */}
        <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between text-[#888888]">
            <span className="text-[12px] font-semibold uppercase tracking-wider">VPS Disk Usage</span>
            <HardDrive className="w-4 h-4 text-[#3EA6FF]" />
          </div>
          <div className="mt-4">
            <span className="text-[28px] font-extrabold text-white">
              {(storageUsedBytes / (1024 * 1024 * 1024)).toFixed(2)} GB
            </span>
            <span className="text-[13px] text-[#AAAAAA] ml-1.5">/ {storageTotalGb} GB</span>
          </div>
          <div className="mt-3 text-[12px] text-emerald-400 font-medium flex items-center gap-1.5">
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
            Export your pending wishlist to your Mac, batch encode with HandBrake (
            <span className="text-white font-mono">Fast 720p30, RF 24</span>), and upload to your {storageTotalGb}GB
            VPS storage for 70% smaller file sizes.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={onExportLinks}
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
  );
};

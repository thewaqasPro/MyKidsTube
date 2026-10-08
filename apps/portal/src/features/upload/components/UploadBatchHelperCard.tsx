import React from 'react';
import { Download, FolderDown, Copy } from 'lucide-react';

interface UploadBatchHelperCardProps {
  handleDownloadTxt: () => void;
  handleCopyLinks: () => void;
}

export const UploadBatchHelperCard: React.FC<UploadBatchHelperCardProps> = ({
  handleDownloadTxt,
  handleCopyLinks,
}) => {
  return (
    <section className="p-6 sm:p-8 bg-surface border-2 border-border rounded-[32px] shadow-xl">
      <div className="flex items-center justify-between pb-5 border-b-2 border-border">
        <div className="flex items-center gap-3.5">
          <div className="flex items-center justify-center w-9 h-9 rounded-2xl bg-gradient-to-tr from-sky to-sky-hover text-white font-display font-black text-base shadow-md shadow-sky/30">
            2
          </div>
          <div>
            <h2 className="text-xl font-display font-black text-white tracking-wide">HandBrake Batch Download Helper</h2>
            <p className="text-xs text-text-muted font-medium mt-0.5">
              Export pending URLs to download locally and encode with HandBrake for 80% smaller files.
            </p>
          </div>
        </div>
        <Download className="w-5 h-5 text-sky" />
      </div>

      <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="p-5 bg-canvas-deep border-2 border-border rounded-2xl space-y-2">
          <span className="text-[11px] font-black text-sky uppercase tracking-wider block">Option A</span>
          <h3 className="text-sm font-display font-bold text-white">Download Text File</h3>
          <p className="text-xs text-text-secondary font-medium">
            Feed `links.txt` directly into 4K Video Downloader or JDownloader.
          </p>
          <button
            onClick={handleDownloadTxt}
            className="w-full mt-3 py-2.5 bg-surface hover:bg-surface-hover text-white text-xs font-bold rounded-xl border border-border transition-all cursor-pointer flex items-center justify-center gap-2 active:scale-95"
          >
            <FolderDown className="w-4 h-4 text-sky" />
            <span>Save links.txt</span>
          </button>
        </div>

        <div className="p-5 bg-canvas-deep border-2 border-border rounded-2xl space-y-2">
          <span className="text-[11px] font-black text-sun uppercase tracking-wider block">Option B</span>
          <h3 className="text-sm font-display font-bold text-white">Copy All URLs</h3>
          <p className="text-xs text-text-secondary font-medium">
            Copies all pending URLs to your clipboard in one tap.
          </p>
          <button
            onClick={handleCopyLinks}
            className="w-full mt-3 py-2.5 bg-surface hover:bg-surface-hover text-white text-xs font-bold rounded-xl border border-border transition-all cursor-pointer flex items-center justify-center gap-2 active:scale-95"
          >
            <Copy className="w-4 h-4 text-sun" />
            <span>Copy URLs</span>
          </button>
        </div>

        <div className="p-5 bg-canvas-deep border-2 border-border rounded-2xl space-y-2">
          <span className="text-[11px] font-black text-mint uppercase tracking-wider block">Option C</span>
          <h3 className="text-sm font-display font-bold text-white">Offline Synced Folders</h3>
          <p className="text-xs text-text-secondary font-medium">
            Save encoded MP4s directly into your synced server folder.
          </p>
          <div className="mt-3 text-xs text-text-secondary font-mono bg-surface p-2.5 rounded-xl border border-border truncate">
            ~/Downloads/MyKidsTube_Optimized
          </div>
        </div>
      </div>
    </section>
  );
};

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
    <section className="p-6 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm">
      <div className="flex items-center justify-between pb-4 border-b border-[#262626]">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-[#3EA6FF] text-black font-bold">
            2
          </div>
          <div>
            <h2 className="text-[17px] font-bold text-white">HandBrake Batch Download Helper</h2>
            <p className="text-[12px] text-[#888888]">
              Export pending URLs to download locally and encode with HandBrake for 80% smaller files.
            </p>
          </div>
        </div>
        <Download className="w-5 h-5 text-[#3EA6FF]" />
      </div>

      <div className="mt-5 grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="p-4 bg-[#121212] border border-[#2A2A2A] rounded-xl space-y-2">
          <span className="text-[12px] font-bold text-[#AAAAAA] uppercase tracking-wider block">Option A</span>
          <h3 className="text-[14px] font-bold text-white">Download Text File</h3>
          <p className="text-[12px] text-[#888888]">
            Feed `links.txt` directly into 4K Video Downloader or JDownloader.
          </p>
          <button
            onClick={handleDownloadTxt}
            className="w-full mt-2 py-2 bg-[#262626] hover:bg-[#333333] text-white text-[12px] font-medium rounded-lg border border-[#3A3A3A] transition-colors cursor-pointer flex items-center justify-center gap-1.5"
          >
            <FolderDown className="w-3.5 h-3.5" />
            <span>Save links.txt</span>
          </button>
        </div>

        <div className="p-4 bg-[#121212] border border-[#2A2A2A] rounded-xl space-y-2">
          <span className="text-[12px] font-bold text-[#AAAAAA] uppercase tracking-wider block">Option B</span>
          <h3 className="text-[14px] font-bold text-white">Copy All URLs</h3>
          <p className="text-[12px] text-[#888888]">
            Copies all pending URLs to your clipboard in one tap.
          </p>
          <button
            onClick={handleCopyLinks}
            className="w-full mt-2 py-2 bg-[#262626] hover:bg-[#333333] text-white text-[12px] font-medium rounded-lg border border-[#3A3A3A] transition-colors cursor-pointer flex items-center justify-center gap-1.5"
          >
            <Copy className="w-3.5 h-3.5" />
            <span>Copy URLs</span>
          </button>
        </div>

        <div className="p-4 bg-[#121212] border border-[#2A2A2A] rounded-xl space-y-2">
          <span className="text-[12px] font-bold text-[#AAAAAA] uppercase tracking-wider block">Option C</span>
          <h3 className="text-[14px] font-bold text-white">Offline Synced Folders</h3>
          <p className="text-[12px] text-[#888888]">
            Save encoded MP4s directly into your synced server folder.
          </p>
          <div className="mt-2 text-[11px] text-[#888888] font-mono bg-[#1A1A1A] p-2 rounded border border-[#333333] truncate">
            ~/Downloads/MyKidsTube_Optimized
          </div>
        </div>
      </div>
    </section>
  );
};

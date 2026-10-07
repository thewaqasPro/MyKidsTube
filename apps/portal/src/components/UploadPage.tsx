import React, { useState } from 'react';
import type { Category, ChildProfile } from '../types/video';
import { 
  ArrowLeft, 
  Upload, 
  Plus, 
  Sparkles, 
  Download, 
  CheckCircle, 
  AlertCircle, 
  FileVideo, 
  Copy, 
  Layers, 
  FolderDown,
  ExternalLink
} from 'lucide-react';
import { StudioTopBar } from './StudioTopBar';
import { StudioSidebar } from './StudioSidebar';

interface UploadPageProps {
  categories: Category[];
  profiles: ChildProfile[];
}

export const UploadPage: React.FC<UploadPageProps> = ({
  categories = [],
  profiles = [],
}) => {
  const [urlsInput, setUrlsInput] = useState('');
  const [categoryId, setCategoryId] = useState(categories[0]?.id || 'cartoons');
  const [selectedProfiles, setSelectedProfiles] = useState<string[]>(() =>
    (profiles || []).map((p) => p.id)
  );

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitResult, setSubmitResult] = useState<{ success: boolean; message: string; count: number; videos: any[] } | null>(null);
  const [errorMessage, setErrorMessage] = useState('');

  // Drag and Drop State
  const [dragOver, setDragOver] = useState(false);
  const [uploadFiles, setUploadFiles] = useState<{ file: File; status: 'queued' | 'uploading' | 'done' | 'error'; progress: number }[]>([]);

  // Studio Shell State
  const [isSidebarExpanded, setIsSidebarExpanded] = useState(true);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);

  const handleAddLinks = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!urlsInput.trim()) return;

    setIsSubmitting(true);
    setErrorMessage('');
    setSubmitResult(null);

    const urls = urlsInput
      .split('\n')
      .map((u) => u.trim())
      .filter((u) => u.length > 0);

    try {
      const res = await fetch('/api/queue/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          urls,
          category_id: categoryId,
          allowed_profile_ids: selectedProfiles,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Failed to add links to queue');
      }

      setSubmitResult(data);
      setUrlsInput('');
    } catch (err: any) {
      setErrorMessage(err.message || 'Error communicating with ingestion service');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCopyLinks = async () => {
    try {
      const res = await fetch('/api/queue/pending?format=txt');
      const text = await res.text();
      await navigator.clipboard.writeText(text);
      alert('Copied all pending links to clipboard! Paste them into your desktop downloader.');
    } catch {
      alert('Failed to copy links');
    }
  };

  const handleDownloadTxt = () => {
    window.location.href = '/api/queue/pending?format=txt';
  };

  const handleFilesDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);

    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      const newFiles = Array.from(e.dataTransfer.files)
        .filter((f) => f.name.endsWith('.mp4') || f.name.endsWith('.webm'))
        .map((f) => ({ file: f, status: 'queued' as const, progress: 0 }));

      setUploadFiles((prev) => [...prev, ...newFiles]);
    }
  };

  const toggleProfile = (id: string) => {
    if (selectedProfiles.includes(id)) {
      setSelectedProfiles(selectedProfiles.filter((p) => p !== id));
    } else {
      setSelectedProfiles([...selectedProfiles, id]);
    }
  };

  return (
    <div className="min-h-screen bg-[#0F0F0F] text-[#F1F1F1] flex flex-col font-sans">
      {/* 1. Studio Top Bar */}
      <StudioTopBar
        onToggleSidebar={() => {
          if (window.innerWidth < 1024) {
            setIsMobileSidebarOpen((prev) => !prev);
          } else {
            setIsSidebarExpanded((prev) => !prev);
          }
        }}
      />

      {/* 2. Main Flex Layout: Studio Sidebar + Upload Workspace */}
      <div className="flex flex-1 relative overflow-x-hidden">
        {/* Dedicated Studio Sidebar */}
        <StudioSidebar
          activeTab="upload"
          isExpanded={isSidebarExpanded}
          isMobileOpen={isMobileSidebarOpen}
          onCloseMobile={() => setIsMobileSidebarOpen(false)}
        />

        {/* Main Workspace */}
        <main className="flex-1 min-w-0 p-4 sm:p-6 md:p-8 space-y-8 max-w-5xl">
        {/* Step 1: Fast Link Ingestion */}
        <section className="p-6 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm">
          <div className="flex items-center justify-between pb-4 border-b border-[#262626]">
            <div className="flex items-center gap-3">
              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-[#FF0000] text-white font-bold">
                1
              </div>
              <div>
                <h2 className="text-[17px] font-bold text-white">Paste YouTube URLs (Single or Bulk)</h2>
                <p className="text-[12px] text-[#888888]">
                  Instantly fetches titles and thumbnails. Immediately playable via YouTube Embed!
                </p>
              </div>
            </div>
            <Sparkles className="w-5 h-5 text-amber-400" />
          </div>

          <form onSubmit={handleAddLinks} className="mt-5 space-y-5">
            <div>
              <label className="block text-[13px] font-medium text-[#DDDDDD] mb-1.5">
                Paste Video or Shorts URLs (One URL per line)
              </label>
              <textarea
                rows={4}
                required
                value={urlsInput}
                onChange={(e) => setUrlsInput(e.target.value)}
                placeholder="https://www.youtube.com/watch?v=...&#10;https://www.youtube.com/shorts/...&#10;https://youtu.be/..."
                className="w-full p-3.5 bg-[#121212] border border-[#333333] focus:border-[#3EA6FF] text-[13px] text-white rounded-xl outline-none transition-colors font-mono"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-[13px] font-medium text-[#DDDDDD] mb-1.5">
                  Category
                </label>
                <select
                  value={categoryId}
                  onChange={(e) => setCategoryId(e.target.value)}
                  className="w-full h-11 px-3 bg-[#121212] border border-[#333333] focus:border-[#3EA6FF] text-[13px] text-white rounded-xl outline-none cursor-pointer"
                >
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-[13px] font-medium text-[#DDDDDD] mb-1.5">
                  Assign to Child Profiles
                </label>
                <div className="flex flex-wrap gap-2 pt-1">
                  {profiles.map((p) => {
                    const isSelected = selectedProfiles.includes(p.id);
                    return (
                      <button
                        type="button"
                        key={p.id}
                        onClick={() => toggleProfile(p.id)}
                        className={`px-3 py-1.5 rounded-lg text-[12px] font-medium border transition-colors cursor-pointer ${
                          isSelected
                            ? 'bg-[#3EA6FF]/20 text-[#3EA6FF] border-[#3EA6FF]/50'
                            : 'bg-[#121212] text-[#888888] border-[#333333]'
                        }`}
                      >
                        {p.name}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            {errorMessage && (
              <div className="p-3 bg-red-950/50 border border-red-800 text-red-200 rounded-xl text-[13px] flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{errorMessage}</span>
              </div>
            )}

            {submitResult && (
              <div className="p-4 bg-emerald-950/40 border border-emerald-800 text-emerald-200 rounded-xl space-y-2">
                <div className="flex items-center gap-2 font-semibold text-[14px]">
                  <CheckCircle className="w-4 h-4 text-emerald-400" />
                  <span>{submitResult.message}</span>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-2">
                  {submitResult.videos.map((v: any) => (
                    <div key={v.id} className="flex items-center gap-2.5 p-2 bg-black/40 rounded-lg">
                      <img src={v.thumbnail_url} alt={v.title} className="w-12 h-8 rounded object-cover" />
                      <div className="min-w-0">
                        <span className="text-[12px] text-white line-clamp-1 font-medium">{v.title}</span>
                        <span className="text-[10px] text-[#AAAAAA]">{v.channel_name}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full h-11 bg-[#FF0000] hover:bg-[#E00000] disabled:opacity-50 text-white font-semibold text-[14px] rounded-xl shadow-sm transition-all cursor-pointer flex items-center justify-center gap-2"
            >
              <Plus className="w-4 h-4" />
              <span>{isSubmitting ? 'Fetching Safe Metadata...' : 'Add to Wishlist & Make Immediately Playable'}</span>
            </button>
          </form>
        </section>

        {/* Step 2: HandBrake Export & Helper */}
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
                <span>Copy to Clipboard</span>
              </button>
            </div>

            <div className="p-4 bg-[#121212] border border-[#2A2A2A] rounded-xl space-y-1.5">
              <span className="text-[12px] font-bold text-amber-400 uppercase tracking-wider block">HandBrake Preset</span>
              <ul className="text-[11px] text-[#BBBBBB] space-y-1">
                <li>• Preset: <strong className="text-white">Fast 720p30</strong></li>
                <li>• Format: <strong className="text-white">MP4 (Web Optimized)</strong></li>
                <li>• Quality: <strong className="text-white">RF 24–26</strong></li>
                <li>• Audio: <strong className="text-white">AAC 96kbps</strong></li>
              </ul>
            </div>
          </div>
        </section>

        {/* Step 3: Batch Upload Dropzone */}
        <section className="p-6 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm">
          <div className="flex items-center justify-between pb-4 border-b border-[#262626]">
            <div className="flex items-center gap-3">
              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-emerald-500 text-black font-bold">
                3
              </div>
              <div>
                <h2 className="text-[17px] font-bold text-white">Drop HandBrake MP4s (Auto-Matches YouTube IDs)</h2>
                <p className="text-[12px] text-[#888888]">
                  Drag and drop 1 to 50 encoded MP4 files. Automatically matches pending catalog items!
                </p>
              </div>
            </div>
            <FileVideo className="w-5 h-5 text-emerald-400" />
          </div>

          <div
            onDragOver={(e) => {
              e.preventDefault();
              setDragOver(true);
            }}
            onDragLeave={() => setDragOver(false)}
            onDrop={handleFilesDrop}
            className={`mt-5 p-10 border-2 border-dashed rounded-2xl flex flex-col items-center justify-center text-center transition-all ${
              dragOver
                ? 'border-[#3EA6FF] bg-[#3EA6FF]/10 scale-[1.01]'
                : 'border-[#333333] hover:border-[#444444] bg-[#121212]'
            }`}
          >
            <div className="w-14 h-14 rounded-2xl bg-[#202020] border border-[#2E2E2E] flex items-center justify-center text-[#AAAAAA] mb-3">
              <Upload className="w-6 h-6 text-[#3EA6FF]" />
            </div>
            <h3 className="text-[16px] font-bold text-white">Drag & drop your HandBrake MP4 files here</h3>
            <p className="text-[12px] text-[#888888] mt-1 max-w-sm">
              Files named with the YouTube ID (e.g. <code className="text-[#3EA6FF]">XqZsoesa55w.mp4</code> or <code className="text-[#3EA6FF]">Video [XqZsoesa55w].mp4</code>) will auto-pair.
            </p>
          </div>

          {/* Queued Files List */}
          {uploadFiles.length > 0 && (
            <div className="mt-4 space-y-2">
              <h4 className="text-[13px] font-semibold text-white">Queued Files ({uploadFiles.length})</h4>
              <div className="space-y-1.5 max-h-48 overflow-y-auto">
                {uploadFiles.map((item, idx) => (
                  <div key={idx} className="flex items-center justify-between p-2.5 bg-[#121212] rounded-xl border border-[#262626] text-[12px]">
                    <span className="font-mono text-white truncate max-w-xs">{item.file.name}</span>
                    <span className="text-[#888888]">{(item.file.size / (1024 * 1024)).toFixed(1)} MB</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </section>
      </main>
      </div>
    </div>
  );
};

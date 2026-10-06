import React, { useState } from 'react';
import { X, Download, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';
import type { Category, ChildProfile } from '../types/video';

interface IngestModalProps {
  isOpen: boolean;
  onClose: () => void;
  categories: Category[];
  profiles: ChildProfile[];
  onVideoIngested?: () => void;
}

export const IngestModal: React.FC<IngestModalProps> = ({
  isOpen,
  onClose,
  categories = [],
  profiles = [],
  onVideoIngested,
}) => {
  const [url, setUrl] = useState('');
  const [categoryId, setCategoryId] = useState('cartoons');
  const [selectedProfiles, setSelectedProfiles] = useState<string[]>(() =>
    (profiles || []).map((p) => p.id)
  );
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [statusMsg, setStatusMsg] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!url.trim()) return;

    setStatus('loading');
    setStatusMsg('Submitting ingestion request to backend queue...');

    try {
      const res = await fetch('/api/ingest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          url: url.trim(),
          category_id: categoryId,
          quality: '720p',
          allowed_profile_ids: selectedProfiles,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.detail || data.message || 'Failed to submit ingestion job');
      }

      setStatus('success');
      setStatusMsg('Video added to background download queue! It will process and appear in your catalog.');
      setUrl('');
      if (onVideoIngested) onVideoIngested();
    } catch (err: any) {
      setStatus('error');
      setStatusMsg(err.message || 'Network error occurred while contacting backend');
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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
      <div className="w-full max-w-lg bg-[#1F1F1F] border border-[#333333] rounded-2xl shadow-2xl p-6 text-white animate-in fade-in zoom-in-95 duration-150">
        <div className="flex items-center justify-between pb-4 border-b border-[#2C2C2C]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-[#FF0000] flex items-center justify-center text-white">
              <Download className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-[17px] font-bold">Add YouTube Video</h3>
              <p className="text-[12px] text-[#AAAAAA]">Download & add safe content to your kids library</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-full text-[#AAAAAA] hover:text-white hover:bg-[#2A2A2A] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="mt-5 space-y-4">
          <div>
            <label className="block text-[13px] font-medium text-[#DDDDDD] mb-1.5">
              YouTube Video or Shorts URL
            </label>
            <input
              type="url"
              required
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              placeholder="https://www.youtube.com/watch?v=... or Shorts"
              className="w-full h-11 px-3.5 bg-[#141414] border border-[#3A3A3A] focus:border-[#3EA6FF] text-[14px] text-white rounded-xl outline-none transition-colors"
            />
          </div>

          <div>
            <label className="block text-[13px] font-medium text-[#DDDDDD] mb-1.5">
              Category
            </label>
            <select
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
              className="w-full h-11 px-3 bg-[#141414] border border-[#3A3A3A] focus:border-[#3EA6FF] text-[14px] text-white rounded-xl outline-none transition-colors cursor-pointer"
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
            <div className="flex flex-wrap gap-2">
              {profiles.map((p) => {
                const isSelected = selectedProfiles.includes(p.id);
                return (
                  <button
                    type="button"
                    key={p.id}
                    onClick={() => toggleProfile(p.id)}
                    className={`px-3 py-1.5 rounded-lg text-[12px] font-medium transition-colors cursor-pointer border ${
                      isSelected
                        ? 'bg-[#3EA6FF]/20 text-[#3EA6FF] border-[#3EA6FF]/50'
                        : 'bg-[#181818] text-[#888888] border-[#333333]'
                    }`}
                  >
                    {p.name}
                  </button>
                );
              })}
            </div>
          </div>

          {status === 'loading' && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-[#222222] text-[#3EA6FF] text-[13px]">
              <Loader2 className="w-4 h-4 animate-spin" />
              <span>{statusMsg}</span>
            </div>
          )}

          {status === 'success' && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-emerald-950/40 border border-emerald-800 text-emerald-400 text-[13px]">
              <CheckCircle className="w-4 h-4 shrink-0" />
              <span>{statusMsg}</span>
            </div>
          )}

          {status === 'error' && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-rose-950/40 border border-rose-800 text-rose-400 text-[13px]">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{statusMsg}</span>
            </div>
          )}

          <div className="pt-2 flex justify-end gap-2.5">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 rounded-xl text-[13px] font-medium text-[#AAAAAA] hover:text-white hover:bg-[#2A2A2A] transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={status === 'loading'}
              className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#FF0000] hover:bg-[#CC0000] active:scale-95 text-white text-[13px] font-medium transition-all cursor-pointer disabled:opacity-50"
            >
              <Download className="w-4 h-4" />
              <span>Start Ingest</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

import React from 'react';
import type { Category, ChildProfile } from '@/types/video';
import type { SubmitResult } from '../types';
import { Plus, AlertCircle, CheckCircle } from 'lucide-react';

interface UploadBulkUrlsCardProps {
  urlsInput: string;
  setUrlsInput: (urls: string) => void;
  setPlaylistUrl: (url: string) => void;
  setIngestMode: (mode: 'playlist' | 'urls') => void;
  categoryId: string;
  setCategoryId: (id: string) => void;
  categories: Category[];
  profiles: ChildProfile[];
  selectedProfiles: string[];
  toggleProfile: (id: string) => void;
  isSubmitting: boolean;
  errorMessage: string;
  submitResult: SubmitResult | null;
  handleAddLinks: (e: React.FormEvent) => void;
}

export const UploadBulkUrlsCard: React.FC<UploadBulkUrlsCardProps> = ({
  urlsInput,
  setUrlsInput,
  setPlaylistUrl,
  setIngestMode,
  categoryId,
  setCategoryId,
  categories,
  profiles,
  selectedProfiles,
  toggleProfile,
  isSubmitting,
  errorMessage,
  submitResult,
  handleAddLinks,
}) => {
  return (
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
        {urlsInput.includes('list=') && (
          <div className="mt-2 p-2.5 bg-blue-950/40 border border-blue-800/60 rounded-xl text-[12px] text-blue-200 flex items-center justify-between">
            <span>This URL contains a playlist parameter! Switch to Playlist mode to preview and batch-import all items.</span>
            <button
              type="button"
              onClick={() => {
                setPlaylistUrl(urlsInput.split('\n')[0].trim());
                setIngestMode('playlist');
              }}
              className="px-2.5 py-1 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-[11px] font-semibold transition-colors cursor-pointer"
            >
              Switch to Playlist Mode
            </button>
          </div>
        )}
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
  );
};

import React from 'react';
import type { Category, ChildProfile } from '@/types/video';
import type { ExtractedPlaylist } from '../types';
import { 
  Sparkles, 
  CheckCircle, 
  AlertCircle, 
  ExternalLink, 
  CheckSquare, 
  Square, 
  Loader2, 
  Film,
  Plus
} from 'lucide-react';

interface UploadPlaylistCardProps {
  playlistUrl: string;
  setPlaylistUrl: (url: string) => void;
  isExtracting: boolean;
  extractError: string;
  extractedPlaylist: ExtractedPlaylist | null;
  selectedIds: Set<string>;
  isImportingPlaylist: boolean;
  playlistImportResult: { count: number; message: string } | null;
  handleInspectPlaylist: (e?: React.FormEvent) => void;
  handleImportSelected: () => void;
  toggleSelectAll: () => void;
  toggleVideo: (id: string) => void;
  categoryId: string;
  setCategoryId: (id: string) => void;
  categories: Category[];
  profiles: ChildProfile[];
  selectedProfiles: string[];
  toggleProfile: (id: string) => void;
}

export const UploadPlaylistCard: React.FC<UploadPlaylistCardProps> = ({
  playlistUrl,
  setPlaylistUrl,
  isExtracting,
  extractError,
  extractedPlaylist,
  selectedIds,
  isImportingPlaylist,
  playlistImportResult,
  handleInspectPlaylist,
  handleImportSelected,
  toggleSelectAll,
  toggleVideo,
  categoryId,
  setCategoryId,
  categories,
  profiles,
  selectedProfiles,
  toggleProfile,
}) => {
  return (
    <div className="mt-5 space-y-5">
      <div>
        <label className="block text-[13px] font-medium text-[#DDDDDD] mb-1.5">
          YouTube Playlist or Radio/Mix URL
        </label>
        <div className="flex flex-col sm:flex-row gap-2.5">
          <input
            type="url"
            value={playlistUrl}
            onChange={(e) => setPlaylistUrl(e.target.value)}
            placeholder="https://www.youtube.com/watch?v=We2DYPbILP8&list=RD... or https://www.youtube.com/playlist?list=..."
            className="flex-1 p-3.5 bg-[#121212] border border-[#333333] focus:border-[#3EA6FF] text-[13px] text-white rounded-xl outline-none transition-colors font-mono"
          />
          <button
            type="button"
            disabled={isExtracting || !playlistUrl.trim()}
            onClick={() => handleInspectPlaylist()}
            className="h-11 sm:h-auto px-6 bg-[#262626] hover:bg-[#333333] disabled:opacity-50 text-white font-semibold text-[13px] rounded-xl border border-[#3A3A3A] transition-all cursor-pointer flex items-center justify-center gap-2 shrink-0"
          >
            {isExtracting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin text-[#3EA6FF]" />
                <span>Inspecting Playlist...</span>
              </>
            ) : (
              <>
                <Sparkles className="w-4 h-4 text-amber-400" />
                <span>Inspect Playlist</span>
              </>
            )}
          </button>
        </div>
        <p className="text-[11px] text-[#777777] mt-1.5">
          Supports public playlists, kids channel mixes, and radio playlists with <code className="text-[#3EA6FF]">list=</code> parameters.
        </p>
      </div>

      {/* Common Category and Profile Assignments */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
        <div>
          <label className="block text-[13px] font-medium text-[#DDDDDD] mb-1.5">
            Assign to Category
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

      {extractError && (
        <div className="p-3.5 bg-red-950/50 border border-red-800 text-red-200 rounded-xl text-[13px] flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{extractError}</span>
        </div>
      )}

      {playlistImportResult && (
        <div className="p-4 bg-emerald-950/40 border border-emerald-800 text-emerald-200 rounded-xl flex items-center justify-between">
          <div className="flex items-center gap-2.5 font-semibold text-[14px]">
            <CheckCircle className="w-5 h-5 text-emerald-400 shrink-0" />
            <span>{playlistImportResult.message}</span>
          </div>
          <a
            href="/studio"
            className="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white text-[12px] font-semibold rounded-lg transition-colors inline-flex items-center gap-1.5"
          >
            <Film className="w-3.5 h-3.5" />
            <span>View in Studio</span>
          </a>
        </div>
      )}

      {/* Extracted Playlist Preview & Selection */}
      {extractedPlaylist && (
        <div className="p-4 sm:p-5 bg-[#121212] border border-[#2A2A2A] rounded-2xl space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 border-b border-[#262626] gap-2">
            <div>
              <span className="text-[11px] font-bold text-[#AAAAAA] uppercase tracking-wider block">
                Playlist Discovered
              </span>
              <h3 className="text-[15px] font-bold text-white line-clamp-1">
                {extractedPlaylist.playlist_title}
              </h3>
            </div>

            <div className="flex items-center gap-3">
              <span className="text-[12px] text-[#AAAAAA]">
                <strong className="text-white">{selectedIds.size}</strong> of {extractedPlaylist.videos.length} selected
              </span>
              <button
                type="button"
                onClick={toggleSelectAll}
                className="px-3 py-1 bg-[#262626] hover:bg-[#333333] text-white text-[12px] font-medium rounded-lg border border-[#3A3A3A] transition-colors cursor-pointer"
              >
                {selectedIds.size === extractedPlaylist.videos.length ? 'Deselect All' : 'Select All'}
              </button>
            </div>
          </div>

          {/* Scrollable list of videos with checkboxes */}
          <div className="max-h-96 overflow-y-auto space-y-2 pr-1 custom-scrollbar">
            {extractedPlaylist.videos.map((vid) => {
              const isChecked = selectedIds.has(vid.id);
              return (
                <div
                  key={vid.id}
                  onClick={() => toggleVideo(vid.id)}
                  className={`p-2.5 rounded-xl border flex items-center gap-3 cursor-pointer transition-all ${
                    isChecked
                      ? 'bg-[#1C1C1C] border-[#3EA6FF]/40 text-white'
                      : 'bg-[#151515] border-[#262626] text-[#777777] opacity-60'
                  }`}
                >
                  <div className="shrink-0 text-[#3EA6FF]">
                    {isChecked ? (
                      <CheckSquare className="w-5 h-5 text-[#3EA6FF]" />
                    ) : (
                      <Square className="w-5 h-5 text-[#555555]" />
                    )}
                  </div>

                  <img
                    src={vid.thumbnail_url}
                    alt={vid.title}
                    className="w-16 h-10 rounded-lg object-cover bg-black shrink-0"
                  />

                  <div className="min-w-0 flex-1">
                    <span className="text-[13px] font-semibold line-clamp-1 block text-white">
                      {vid.title}
                    </span>
                    <span className="text-[11px] text-[#888888]">
                      {vid.channel_name} • ID: {vid.id}
                    </span>
                  </div>

                  <a
                    href={vid.youtube_url}
                    target="_blank"
                    rel="noreferrer"
                    onClick={(e) => e.stopPropagation()}
                    className="p-1.5 text-[#666666] hover:text-white rounded-lg transition-colors shrink-0"
                    title="Open on YouTube"
                  >
                    <ExternalLink className="w-4 h-4" />
                  </a>
                </div>
              );
            })}
          </div>

          {/* Import Action Button */}
          <button
            type="button"
            disabled={isImportingPlaylist || selectedIds.size === 0}
            onClick={handleImportSelected}
            className="w-full h-11 bg-[#FF0000] hover:bg-[#E00000] disabled:opacity-50 text-white font-semibold text-[14px] rounded-xl shadow-sm transition-all cursor-pointer flex items-center justify-center gap-2"
          >
            {isImportingPlaylist ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Importing {selectedIds.size} Videos & Caching Thumbnails...</span>
              </>
            ) : (
              <>
                <Plus className="w-4 h-4" />
                <span>Import {selectedIds.size} Selected Video{selectedIds.size !== 1 ? 's' : ''} to Kids Catalog</span>
              </>
            )}
          </button>
        </div>
      )}
    </div>
  );
};

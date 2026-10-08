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
        <label className="block text-[13px] font-medium text-text-primary mb-1.5">
          YouTube Playlist or Radio/Mix URL
        </label>
        <div className="flex flex-col sm:flex-row gap-2.5">
          <input
            type="url"
            value={playlistUrl}
            onChange={(e) => setPlaylistUrl(e.target.value)}
            placeholder="https://www.youtube.com/watch?v=We2DYPbILP8&list=RD... or https://www.youtube.com/playlist?list=..."
            className="flex-1 p-3.5 bg-surface-elevated border border-border focus:border-sky text-[13px] text-text-primary rounded-xl outline-none transition-colors font-mono"
          />
          <button
            type="button"
            disabled={isExtracting || !playlistUrl.trim()}
            onClick={() => handleInspectPlaylist()}
            className="h-11 sm:h-auto px-6 bg-surface-elevated hover:bg-surface-hover disabled:opacity-50 text-text-primary font-semibold text-[13px] rounded-xl border border-border transition-all cursor-pointer flex items-center justify-center gap-2 shrink-0"
          >
            {isExtracting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin text-sky" />
                <span>Inspecting Playlist...</span>
              </>
            ) : (
              <>
                <Sparkles className="w-4 h-4 text-sun" />
                <span>Inspect Playlist</span>
              </>
            )}
          </button>
        </div>
        <p className="text-[11px] text-text-muted mt-1.5">
          Supports public playlists, kids channel mixes, and radio playlists with <code className="text-sky">list=</code> parameters.
        </p>
      </div>

      {/* Common Category and Profile Assignments */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
        <div>
          <label className="block text-[13px] font-medium text-text-primary mb-1.5">
            Assign to Category
          </label>
          <select
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            className="w-full h-11 px-3 bg-surface-elevated border border-border focus:border-sky text-[13px] text-text-primary rounded-xl outline-none cursor-pointer"
          >
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-[13px] font-medium text-text-primary mb-1.5">
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
                      ? 'bg-sky/20 text-sky border-sky/50 font-bold'
                      : 'bg-surface-elevated text-text-secondary border-border hover:bg-surface-hover'
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
        <div className="p-3.5 bg-coral/20 border border-coral/40 text-coral rounded-xl text-[13px] flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{extractError}</span>
        </div>
      )}

      {playlistImportResult && (
        <div className="p-4 bg-mint/15 border border-mint/30 text-mint rounded-xl flex items-center justify-between">
          <div className="flex items-center gap-2.5 font-semibold text-[14px]">
            <CheckCircle className="w-5 h-5 text-mint shrink-0" />
            <span>{playlistImportResult.message}</span>
          </div>
          <a
            href="/studio"
            className="px-3.5 py-1.5 bg-mint hover:bg-mint-hover text-white text-[12px] font-semibold rounded-lg transition-colors inline-flex items-center gap-1.5"
          >
            <Film className="w-3.5 h-3.5" />
            <span>View in Studio</span>
          </a>
        </div>
      )}

      {/* Extracted Playlist Preview & Selection */}
      {extractedPlaylist && (
        <div className="p-4 sm:p-5 bg-surface border border-border rounded-2xl space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 border-b border-border gap-2">
            <div>
              <span className="text-[11px] font-bold text-text-secondary uppercase tracking-wider block">
                Playlist Discovered
              </span>
              <h3 className="text-[15px] font-bold text-text-primary line-clamp-1">
                {extractedPlaylist.playlist_title}
              </h3>
            </div>

            <div className="flex items-center gap-3">
              <span className="text-[12px] text-text-secondary">
                <strong className="text-text-primary">{selectedIds.size}</strong> of {extractedPlaylist.videos.length} selected
              </span>
              <button
                type="button"
                onClick={toggleSelectAll}
                className="px-3 py-1 bg-surface-elevated hover:bg-surface-hover text-text-primary text-[12px] font-medium rounded-lg border border-border transition-colors cursor-pointer"
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
                      ? 'bg-surface-elevated border-sky/40 text-text-primary'
                      : 'bg-surface border-border text-text-muted opacity-60 hover:opacity-90'
                  }`}
                >
                  <div className="shrink-0 text-sky">
                    {isChecked ? (
                      <CheckSquare className="w-5 h-5 text-sky" />
                    ) : (
                      <Square className="w-5 h-5 text-text-muted" />
                    )}
                  </div>

                  <img
                    src={vid.thumbnail_url}
                    alt={vid.title}
                    className="w-16 h-10 rounded-lg object-cover bg-black shrink-0"
                  />

                  <div className="min-w-0 flex-1">
                    <span className="text-[13px] font-semibold line-clamp-1 block text-text-primary">
                      {vid.title}
                    </span>
                    <span className="text-[11px] text-text-secondary">
                      {vid.channel_name} • ID: {vid.id}
                    </span>
                  </div>

                  <a
                    href={vid.youtube_url}
                    target="_blank"
                    rel="noreferrer"
                    onClick={(e) => e.stopPropagation()}
                    className="p-1.5 text-text-muted hover:text-text-primary rounded-lg transition-colors shrink-0"
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
            className="w-full h-12 bg-gradient-to-r from-coral to-coral-hover disabled:opacity-50 text-white font-display font-black text-sm rounded-2xl shadow-lg shadow-coral/20 transition-all cursor-pointer flex items-center justify-center gap-2 active:scale-95 border border-white/10"
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

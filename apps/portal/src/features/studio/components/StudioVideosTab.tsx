import React from 'react';
import type { Video, Category } from '@/types/video';
import {
  Search,
  Filter,
  Trash2,
  Play,
  CheckCircle,
  Sparkles,
  CheckSquare,
  Square,
  Plus,
} from 'lucide-react';
import { getThumbnailUrl, isSelfHosted, isVideoShort } from '@/lib/constants';

export interface StudioVideosTabProps {
  videos: Video[];
  categories: Category[];
  search: string;
  onSearchChange: (q: string) => void;
  statusFilter: 'all' | 'ready' | 'pending';
  onStatusFilterChange: (status: 'all' | 'ready' | 'pending') => void;
  categoryFilter: string;
  onCategoryFilterChange: (cat: string) => void;
  selectedIds: Set<string>;
  onToggleSelect: (id: string, e: React.MouseEvent) => void;
  onSelectAll: () => void;
  onDeselectAll: () => void;
  onSingleDelete: (id: string) => void;
  onBulkDelete: () => void;
  isDeletingId: string | null;
}

export const StudioVideosTab: React.FC<StudioVideosTabProps> = ({
  videos,
  categories,
  search,
  onSearchChange,
  statusFilter,
  onStatusFilterChange,
  categoryFilter,
  onCategoryFilterChange,
  selectedIds,
  onToggleSelect,
  onSelectAll,
  onDeselectAll,
  onSingleDelete,
  onBulkDelete,
  isDeletingId,
}) => {
  const isAllSelected = videos.length > 0 && videos.every((v) => selectedIds.has(v.id));
  const someSelected = videos.some((v) => selectedIds.has(v.id));

  return (
    <section className="space-y-4">
      {/* Search and Filters Toolbar */}
      <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 bg-surface p-3.5 rounded-2xl border border-border">
        {/* Search */}
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-text-muted" />
          <input
            type="text"
            value={search}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Filter by title, channel name, or video ID..."
            className="w-full pl-9 pr-4 py-2 bg-surface-elevated border border-border rounded-xl text-[13px] text-text-primary placeholder-text-muted focus:outline-none focus:border-sky transition-colors"
          />
        </div>

        {/* Filter controls */}
        <div className="flex flex-wrap items-center gap-2">
          {/* Status filter */}
          <div className="flex items-center bg-surface-elevated border border-border rounded-xl p-0.5 text-[12px]">
            <button
              onClick={() => onStatusFilterChange('all')}
              className={`px-3 py-1.5 rounded-lg font-medium transition-colors cursor-pointer ${
                statusFilter === 'all' ? 'bg-surface text-text-primary font-bold shadow-sm' : 'text-text-secondary hover:text-text-primary'
              }`}
            >
              All
            </button>
            <button
              onClick={() => onStatusFilterChange('ready')}
              className={`px-3 py-1.5 rounded-lg font-medium transition-colors cursor-pointer ${
                statusFilter === 'ready' ? 'bg-surface text-mint font-bold shadow-sm' : 'text-text-secondary hover:text-text-primary'
              }`}
            >
              Self-Hosted
            </button>
            <button
              onClick={() => onStatusFilterChange('pending')}
              className={`px-3 py-1.5 rounded-lg font-medium transition-colors cursor-pointer ${
                statusFilter === 'pending' ? 'bg-surface text-sun font-bold shadow-sm' : 'text-text-secondary hover:text-text-primary'
              }`}
            >
              Wishlist
            </button>
          </div>

          {/* Category Dropdown */}
          <div className="relative">
            <select
              value={categoryFilter}
              onChange={(e) => onCategoryFilterChange(e.target.value)}
              className="appearance-none bg-surface-elevated border border-border text-[12px] text-text-primary px-3.5 py-2 pr-8 rounded-xl outline-none cursor-pointer focus:border-sky"
            >
              <option value="all">All Categories</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
            <Filter className="w-3.5 h-3.5 text-text-muted absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          </div>

          <a
            href="/upload"
            className="flex items-center gap-1.5 px-4 py-2 bg-gradient-to-r from-coral to-coral-hover text-white text-xs font-display font-black rounded-full transition-all shrink-0 shadow-md shadow-coral/20 no-underline active:scale-95 border border-white/10"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Add Video</span>
          </a>
        </div>
      </div>

      {/* Bulk Selection Bar */}
      {selectedIds.size > 0 && (
        <div className="flex items-center justify-between p-3.5 bg-gradient-to-r from-coral/20 to-surface border border-coral/30 rounded-2xl shadow-sm animate-fadeIn">
          <div className="flex items-center gap-3">
            <button
              onClick={onDeselectAll}
              className="text-text-secondary hover:text-text-primary text-[12px] underline cursor-pointer"
            >
              Deselect all
            </button>
            <span className="text-[13px] font-semibold text-text-primary">
              {selectedIds.size} video{selectedIds.size > 1 ? 's' : ''} selected
            </span>
          </div>

          <button
            onClick={onBulkDelete}
            className="flex items-center gap-2 px-4 py-1.5 bg-coral hover:bg-coral-hover text-white text-[12px] font-semibold rounded-xl transition-colors cursor-pointer shadow-md shadow-coral/20"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span>Delete Selected ({selectedIds.size})</span>
          </button>
        </div>
      )}

      {/* Catalog Table */}
      <div className="bg-surface border border-border rounded-2xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-[13px]">
            <thead className="bg-surface-elevated text-text-secondary border-b border-border select-none text-[12px]">
              <tr>
                <th className="py-3 px-3 w-10 text-center">
                  <button
                    type="button"
                    onClick={isAllSelected ? onDeselectAll : onSelectAll}
                    className="text-text-secondary hover:text-text-primary transition-colors cursor-pointer p-1"
                    title={isAllSelected ? 'Deselect all videos' : 'Select all videos'}
                  >
                    {isAllSelected ? (
                      <CheckSquare className="w-4 h-4 text-sky" />
                    ) : someSelected ? (
                      <div className="w-4 h-4 rounded border border-sky bg-sky/20 flex items-center justify-center">
                        <div className="w-2 h-0.5 bg-sky" />
                      </div>
                    ) : (
                      <Square className="w-4 h-4 text-text-muted" />
                    )}
                  </button>
                </th>
                <th className="py-3 px-4 font-semibold">Video</th>
                <th className="py-3 px-4 font-semibold hidden md:table-cell">Playback Mode</th>
                <th className="py-3 px-4 font-semibold hidden sm:table-cell">Category</th>
                <th className="py-3 px-4 font-semibold text-center hidden lg:table-cell">Views</th>
                <th className="py-3 px-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {videos.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-text-secondary">
                    No videos found matching your filters.
                  </td>
                </tr>
              ) : (
                videos.map((v) => {
                  const isReady = isSelfHosted(v);
                  const cleanTitle = v.title || 'Untitled Video';
                  const cleanChannel = v.channel_name || 'KidsTube';
                  const thumb = getThumbnailUrl(v);
                  const isChecked = selectedIds.has(v.id);

                  return (
                    <tr
                      key={v.id}
                      className={`transition-colors select-none group ${
                        isChecked ? 'bg-surface-elevated hover:bg-surface-hover' : 'hover:bg-surface-elevated/40'
                      }`}
                    >
                      {/* Multi-Select Checkbox Cell */}
                      <td className="py-3 px-3 text-center">
                        <button
                          type="button"
                          onClick={(e) => onToggleSelect(v.id, e)}
                          className="text-text-secondary hover:text-text-primary transition-colors p-1 cursor-pointer inline-flex items-center justify-center"
                        >
                          {isChecked ? (
                            <CheckSquare className="w-4 h-4 text-sky" />
                          ) : (
                            <Square className="w-4 h-4 text-text-muted group-hover:text-text-secondary" />
                          )}
                        </button>
                      </td>

                      {/* Video Cell */}
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3 min-w-[240px]">
                          <div className="relative w-20 aspect-video rounded-lg overflow-hidden bg-surface-elevated shrink-0 border border-border">
                            <img src={thumb} alt={cleanTitle} className="w-full h-full object-cover" />
                            <div className="absolute bottom-0.5 right-0.5 px-1 rounded bg-sidebar/80 text-[9px] font-mono text-white">
                              {v.duration_formatted || '03:00'}
                            </div>
                          </div>
                          <div className="min-w-0">
                            <a
                              href={isVideoShort(v) ? `/shorts?v=${v.id}` : `/watch/${v.id}`}
                              className="font-medium text-text-primary hover:text-sky line-clamp-1 transition-colors"
                            >
                              {cleanTitle}
                            </a>
                            <span className="text-[11px] text-text-secondary block truncate mt-0.5">
                              {cleanChannel}
                            </span>
                          </div>
                        </div>
                      </td>

                      {/* Playback Mode */}
                      <td className="py-3 px-4 hidden md:table-cell">
                        {isReady ? (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-mint/15 text-mint border border-mint/30">
                            <CheckCircle className="w-3.5 h-3.5" />
                            <span>Self-Hosted MP4</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-sun/15 text-sun border border-sun/30">
                            <Sparkles className="w-3.5 h-3.5" />
                            <span>YouTube Embed</span>
                          </span>
                        )}
                      </td>

                      {/* Category */}
                      <td className="py-3 px-4 hidden sm:table-cell text-text-secondary capitalize">
                        {v.category_id}
                      </td>

                      {/* Views */}
                      <td className="py-3 px-4 text-center font-mono text-text-secondary hidden lg:table-cell">
                        {v.views || 0}
                      </td>

                      {/* Actions */}
                      <td className="py-3 px-4 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          <a
                            href={isVideoShort(v) ? `/shorts?v=${v.id}` : `/watch/${v.id}`}
                            className="p-2 rounded-lg bg-surface-elevated hover:bg-surface-hover text-text-secondary hover:text-text-primary transition-colors"
                            title={isVideoShort(v) ? 'Watch Short' : 'Watch Video'}
                          >
                            <Play className="w-3.5 h-3.5 fill-current" />
                          </a>

                          <button
                            onClick={() => onSingleDelete(v.id)}
                            disabled={isDeletingId === v.id}
                            className="p-2 rounded-lg bg-surface-elevated hover:bg-coral/20 text-text-secondary hover:text-coral transition-colors cursor-pointer disabled:opacity-50"
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
  );
};

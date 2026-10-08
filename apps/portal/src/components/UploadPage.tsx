import React, { useState } from 'react';
import type { Category, ChildProfile } from '@/types/video';
import { ListVideo, Plus } from 'lucide-react';
import { StudioTopBar } from './StudioTopBar';
import { StudioSidebar } from './StudioSidebar';
import type { ExtractedPlaylist, ExtractedVideo, SubmitResult } from '@/features/upload/types';
import { UploadPlaylistCard } from '@/features/upload/components/UploadPlaylistCard';
import { UploadBulkUrlsCard } from '@/features/upload/components/UploadBulkUrlsCard';
import { UploadBatchHelperCard } from '@/features/upload/components/UploadBatchHelperCard';

interface UploadPageProps {
  categories: Category[];
  profiles: ChildProfile[];
}

export const UploadPage: React.FC<UploadPageProps> = ({
  categories = [],
  profiles = [],
}) => {
  // Ingest Mode: 'playlist' | 'urls'
  const [ingestMode, setIngestMode] = useState<'playlist' | 'urls'>('playlist');

  // Playlist Mode State
  const [playlistUrl, setPlaylistUrl] = useState('');
  const [isExtracting, setIsExtracting] = useState(false);
  const [extractError, setExtractError] = useState('');
  const [extractedPlaylist, setExtractedPlaylist] = useState<ExtractedPlaylist | null>(null);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [isImportingPlaylist, setIsImportingPlaylist] = useState(false);
  const [playlistImportResult, setPlaylistImportResult] = useState<{ count: number; message: string } | null>(null);

  // URLs Mode State
  const [urlsInput, setUrlsInput] = useState('');
  const [categoryId, setCategoryId] = useState(categories[0]?.id || 'cartoons');
  const [selectedProfiles, setSelectedProfiles] = useState<string[]>(() =>
    (profiles || []).map((p) => p.id)
  );

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitResult, setSubmitResult] = useState<SubmitResult | null>(null);
  const [errorMessage, setErrorMessage] = useState('');

  // Studio Shell State
  const [isSidebarExpanded, setIsSidebarExpanded] = useState(true);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);

  // 1. Inspect YouTube Playlist
  const handleInspectPlaylist = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const trimmed = playlistUrl.trim();
    if (!trimmed) return;

    setIsExtracting(true);
    setExtractError('');
    setExtractedPlaylist(null);
    setPlaylistImportResult(null);

    try {
      const res = await fetch('/api/playlist/extract', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlist_url: trimmed }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Failed to inspect playlist');
      }

      setExtractedPlaylist(data);
      // Select all videos by default
      setSelectedIds(new Set((data.videos || []).map((v: ExtractedVideo) => v.id)));
    } catch (err: any) {
      setExtractError(err.message || 'Error extracting videos from playlist');
    } finally {
      setIsExtracting(false);
    }
  };

  // 2. Batch Import Selected Playlist Videos
  const handleImportSelected = async () => {
    if (!extractedPlaylist || selectedIds.size === 0) return;

    setIsImportingPlaylist(true);
    setExtractError('');
    setPlaylistImportResult(null);

    const itemsToImport = extractedPlaylist.videos.filter((v) => selectedIds.has(v.id));

    try {
      const res = await fetch('/api/queue/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          items: itemsToImport,
          category_id: categoryId,
          allowed_profile_ids: selectedProfiles,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Failed to import playlist items');
      }

      setPlaylistImportResult({
        count: data.count || itemsToImport.length,
        message: data.message || `Successfully added ${itemsToImport.length} videos to your kids catalog!`,
      });
      setExtractedPlaylist(null);
      setPlaylistUrl('');
    } catch (err: any) {
      setExtractError(err.message || 'Error importing playlist items');
    } finally {
      setIsImportingPlaylist(false);
    }
  };

  const toggleSelectAll = () => {
    if (!extractedPlaylist) return;
    if (selectedIds.size === extractedPlaylist.videos.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(extractedPlaylist.videos.map((v) => v.id)));
    }
  };

  const toggleVideo = (id: string) => {
    const updated = new Set(selectedIds);
    if (updated.has(id)) {
      updated.delete(id);
    } else {
      updated.add(id);
    }
    setSelectedIds(updated);
  };

  // 3. URLs Mode Submit
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

  const toggleProfile = (id: string) => {
    if (selectedProfiles.includes(id)) {
      setSelectedProfiles(selectedProfiles.filter((p) => p !== id));
    } else {
      setSelectedProfiles([...selectedProfiles, id]);
    }
  };

  return (
    <div className="min-h-screen bg-[#0B0F19] text-[#F1F1F1] flex flex-col font-sans">
      <StudioTopBar
        onToggleSidebar={() => {
          if (window.innerWidth < 1024) {
            setIsMobileSidebarOpen((prev) => !prev);
          } else {
            setIsSidebarExpanded((prev) => !prev);
          }
        }}
      />

      <div className="flex flex-1 relative overflow-x-hidden">
        <StudioSidebar
          activeTab="upload"
          isExpanded={isSidebarExpanded}
          isMobileOpen={isMobileSidebarOpen}
          onCloseMobile={() => setIsMobileSidebarOpen(false)}
        />

        <main className="flex-1 min-w-0 p-4 sm:p-6 md:p-8 space-y-8 max-w-5xl">
          {/* Step 1: Ingestion Card */}
          <section className="p-6 sm:p-8 bg-[#151D33] border-2 border-[#1E294B] rounded-[32px] shadow-xl">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-5 border-b-2 border-[#1E294B] gap-4">
              <div className="flex items-center gap-3.5">
                <div className="flex items-center justify-center w-9 h-9 rounded-2xl bg-gradient-to-tr from-[#FF5E62] to-[#FFB300] text-white font-display font-black text-base shadow-md shadow-[#FF5E62]/30">
                  1
                </div>
                <div>
                  <h2 className="text-xl font-display font-black text-white tracking-wide">Add Family Videos</h2>
                  <p className="text-xs text-[#94A3B8] font-medium mt-0.5">
                    Import entire playlists or paste custom URLs. Automatically caches thumbnails and enables instant playback.
                  </p>
                </div>
              </div>

              {/* Mode Switcher Tabs */}
              <div className="flex items-center p-1.5 bg-[#0B0F19] border-2 border-[#1E294B] rounded-2xl self-start sm:self-auto">
                <button
                  type="button"
                  onClick={() => setIngestMode('playlist')}
                  className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                    ingestMode === 'playlist'
                      ? 'bg-gradient-to-r from-[#FF5E62] to-[#FF8E53] text-white shadow-md shadow-[#FF5E62]/30'
                      : 'text-[#94A3B8] hover:text-white'
                  }`}
                >
                  <ListVideo className="w-4 h-4" />
                  <span>Playlist / Mix URL</span>
                </button>
                <button
                  type="button"
                  onClick={() => setIngestMode('urls')}
                  className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                    ingestMode === 'urls'
                      ? 'bg-gradient-to-r from-[#FF5E62] to-[#FF8E53] text-white shadow-md shadow-[#FF5E62]/30'
                      : 'text-[#94A3B8] hover:text-white'
                  }`}
                >
                  <Plus className="w-4 h-4" />
                  <span>Single / Bulk URLs</span>
                </button>
              </div>
            </div>

            {ingestMode === 'playlist' ? (
              <UploadPlaylistCard
                playlistUrl={playlistUrl}
                setPlaylistUrl={setPlaylistUrl}
                isExtracting={isExtracting}
                extractError={extractError}
                extractedPlaylist={extractedPlaylist}
                selectedIds={selectedIds}
                isImportingPlaylist={isImportingPlaylist}
                playlistImportResult={playlistImportResult}
                handleInspectPlaylist={handleInspectPlaylist}
                handleImportSelected={handleImportSelected}
                toggleSelectAll={toggleSelectAll}
                toggleVideo={toggleVideo}
                categoryId={categoryId}
                setCategoryId={setCategoryId}
                categories={categories}
                profiles={profiles}
                selectedProfiles={selectedProfiles}
                toggleProfile={toggleProfile}
              />
            ) : (
              <UploadBulkUrlsCard
                urlsInput={urlsInput}
                setUrlsInput={setUrlsInput}
                setPlaylistUrl={setPlaylistUrl}
                setIngestMode={setIngestMode}
                categoryId={categoryId}
                setCategoryId={setCategoryId}
                categories={categories}
                profiles={profiles}
                selectedProfiles={selectedProfiles}
                toggleProfile={toggleProfile}
                isSubmitting={isSubmitting}
                errorMessage={errorMessage}
                submitResult={submitResult}
                handleAddLinks={handleAddLinks}
              />
            )}
          </section>

          {/* Step 2: HandBrake Export & Helper */}
          <UploadBatchHelperCard
            handleDownloadTxt={handleDownloadTxt}
            handleCopyLinks={handleCopyLinks}
          />
        </main>
      </div>
    </div>
  );
};

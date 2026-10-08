import React, { useState, useEffect, useMemo } from 'react';
import type { Video, Category, ChildProfile } from '@/types/video';
import { X } from 'lucide-react';
import { StudioTopBar } from './StudioTopBar';
import { StudioSidebar } from './StudioSidebar';
import { DeleteConfirmModal } from './DeleteConfirmModal';
import { StudioAnalyticsView } from './StudioAnalyticsView';
import { StudioOverviewTab } from '@/features/studio/components/StudioOverviewTab';
import { StudioVideosTab } from '@/features/studio/components/StudioVideosTab';
import { StudioDevicesTab } from '@/features/studio/components/StudioDevicesTab';
import { StudioSecurityTab } from '@/features/studio/components/StudioSecurityTab';
import { useStudioDevices } from '@/features/studio/hooks/useStudioDevices';
import { useStudioSecurity } from '@/features/studio/hooks/useStudioSecurity';

export interface StudioDashboardProps {
  initialVideos: Video[];
  initialCategories: Category[];
  initialProfiles: ChildProfile[];
  initialStats: any;
  currentUser?: {
    id: string;
    name?: string;
    email?: string;
    role?: string;
  } | null;
}

export const StudioDashboard: React.FC<StudioDashboardProps> = ({
  initialVideos = [],
  initialCategories = [],
  initialProfiles = [],
  initialStats = null,
  currentUser = null,
}) => {
  const [videos, setVideos] = useState<Video[]>(initialVideos || []);
  const stats = initialStats;
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'ready' | 'pending'>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [isDeletingId, setIsDeletingId] = useState<string | null>(null);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [lastSelectedId, setLastSelectedId] = useState<string | null>(null);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Modal State
  const [modalConfig, setModalConfig] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    details?: string;
    confirmLabel?: string;
    action: () => Promise<void>;
  }>({
    isOpen: false,
    title: '',
    message: '',
    action: async () => {},
  });
  const [isModalProcessing, setIsModalProcessing] = useState(false);

  // Shell & Navigation State
  const [activeTab, setActiveTab] = useState<string>('dashboard');
  const [isSidebarExpanded, setIsSidebarExpanded] = useState(true);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);

  // Sub-feature Hooks
  const devices = useStudioDevices({
    initialProfiles,
    setModalConfig,
    setNotification,
  });

  const security = useStudioSecurity();

  // Synchronize URL Hash
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const hash = window.location.hash.replace('#', '');
      if (hash && ['dashboard', 'videos', 'devices', 'analytics', 'settings'].includes(hash)) {
        setActiveTab(hash);
      }
    }
  }, []);

  const handleSelectTab = (tab: string) => {
    setActiveTab(tab);
    if (typeof window !== 'undefined') {
      window.location.hash = tab;
    }
  };

  useEffect(() => {
    if (activeTab === 'devices') devices.fetchDevices();
    else if (activeTab === 'settings') {
      security.fetchPasskeys();
      security.fetchSessions();
      security.fetchPinStatus();
    }
  }, [activeTab]);

  // Video Filtering & Multi-Selection
  const filteredVideos = useMemo(() => {
    return videos.filter((v) => {
      const matchesSearch =
        v.title.toLowerCase().includes(search.toLowerCase()) ||
        (v.channel_name && v.channel_name.toLowerCase().includes(search.toLowerCase())) ||
        v.id.toLowerCase().includes(search.toLowerCase());

      const matchesCategory = categoryFilter === 'all' || v.category_id === categoryFilter;
      const isReady = Boolean(v.file_verified && v.file_verified > 0) || v.status === 'ready';

      if (statusFilter === 'ready' && !isReady) return false;
      if (statusFilter === 'pending' && isReady) return false;
      return matchesSearch && matchesCategory;
    });
  }, [videos, search, categoryFilter, statusFilter]);

  const toggleVideoSelect = (id: string, e: React.MouseEvent) => {
    const next = new Set(selectedIds);
    if (e.shiftKey && lastSelectedId && lastSelectedId !== id) {
      const currentIndex = filteredVideos.findIndex((v) => v.id === id);
      const lastIndex = filteredVideos.findIndex((v) => v.id === lastSelectedId);
      if (currentIndex !== -1 && lastIndex !== -1) {
        const [start, end] = [Math.min(currentIndex, lastIndex), Math.max(currentIndex, lastIndex)];
        for (let i = start; i <= end; i++) next.add(filteredVideos[i].id);
      }
    } else {
      if (next.has(id)) next.delete(id);
      else next.add(id);
      setLastSelectedId(id);
    }
    setSelectedIds(next);
  };

  const selectAll = () => setSelectedIds(new Set(filteredVideos.map((v) => v.id)));
  const deselectAll = () => {
    setSelectedIds(new Set());
    setLastSelectedId(null);
  };

  // Video Deletion Handlers
  const confirmSingleDelete = (id: string) => {
    const vid = videos.find((v) => v.id === id);
    setModalConfig({
      isOpen: true,
      title: 'Delete Video from Catalog?',
      message: `Are you sure you want to remove "${vid?.title || id}"?`,
      details: 'This will purge the video entry from Cloudflare D1 and remove cached files.',
      confirmLabel: 'Delete Video',
      action: async () => {
        setIsDeletingId(id);
        try {
          const res = await fetch(`/api/studio/videos?id=${encodeURIComponent(id)}`, { method: 'DELETE' });
          if (res.ok) {
            setVideos((prev) => prev.filter((v) => v.id !== id));
            setSelectedIds((prev) => {
              const n = new Set(prev);
              n.delete(id);
              return n;
            });
            setNotification({ message: 'Video deleted successfully.', type: 'success' });
            setTimeout(() => setNotification(null), 4000);
          }
        } finally {
          setIsDeletingId(null);
        }
      },
    });
  };

  const confirmBulkDelete = () => {
    const count = selectedIds.size;
    setModalConfig({
      isOpen: true,
      title: `Delete ${count} Selected Videos?`,
      message: `Are you sure you want to remove ${count} videos from the catalog?`,
      details: 'All associated entries will be purged from Cloudflare D1 and storage.',
      confirmLabel: `Delete ${count} Videos`,
      action: async () => {
        const ids = Array.from(selectedIds);
        try {
          const res = await fetch('/api/studio/videos', {
            method: 'DELETE',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ids }),
          });
          if (res.ok) {
            setVideos((prev) => prev.filter((v) => !selectedIds.has(v.id)));
            deselectAll();
            setNotification({ message: `Successfully deleted ${count} videos.`, type: 'success' });
            setTimeout(() => setNotification(null), 4000);
          }
        } catch (e) {
          console.error('Bulk deletion failed:', e);
        }
      },
    });
  };

  return (
    <div className="min-h-screen bg-[#0F0F0F] text-[#F1F1F1] flex flex-col font-sans">
      <StudioTopBar
        searchQuery={search}
        onSearchChange={setSearch}
        onToggleSidebar={() => {
          if (window.innerWidth < 1024) setIsMobileSidebarOpen((prev) => !prev);
          else setIsSidebarExpanded((prev) => !prev);
        }}
      />

      <div className="flex flex-1 relative overflow-x-hidden">
        <StudioSidebar
          activeTab={activeTab}
          onSelectTab={handleSelectTab}
          isExpanded={isSidebarExpanded}
          isMobileOpen={isMobileSidebarOpen}
          onCloseMobile={() => setIsMobileSidebarOpen(false)}
        />

        <main className="flex-1 min-w-0 p-4 sm:p-6 md:p-8 space-y-6">
          {notification && (
            <div
              className={`p-4 rounded-xl flex items-center justify-between text-sm font-medium transition-all ${
                notification.type === 'success'
                  ? 'bg-emerald-950/60 border border-emerald-500/30 text-emerald-300'
                  : 'bg-red-950/60 border border-red-500/30 text-red-300'
              }`}
            >
              <span>{notification.message}</span>
              <button
                onClick={() => setNotification(null)}
                className="text-white/60 hover:text-white ml-4 p-1 rounded-full hover:bg-white/10"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          )}

          {activeTab === 'dashboard' && (
            <StudioOverviewTab
              totalVideos={videos.length}
              readyCount={videos.filter((v) => Boolean(v.file_verified && v.file_verified > 0) || v.status === 'ready').length}
              pendingCount={videos.filter((v) => !(Boolean(v.file_verified && v.file_verified > 0) || v.status === 'ready')).length}
              storageUsedBytes={stats?.storage_used_bytes || 0}
              onExportLinks={() => (window.location.href = '/api/queue/pending?format=txt')}
              onNavigateToVideos={() => handleSelectTab('videos')}
            />
          )}

          {activeTab === 'videos' && (
            <StudioVideosTab
              videos={filteredVideos}
              categories={initialCategories}
              search={search}
              onSearchChange={setSearch}
              statusFilter={statusFilter}
              onStatusFilterChange={setStatusFilter}
              categoryFilter={categoryFilter}
              onCategoryFilterChange={setCategoryFilter}
              selectedIds={selectedIds}
              onToggleSelect={toggleVideoSelect}
              onSelectAll={selectAll}
              onDeselectAll={deselectAll}
              onSingleDelete={confirmSingleDelete}
              onBulkDelete={confirmBulkDelete}
              isDeletingId={isDeletingId}
            />
          )}

          {activeTab === 'devices' && (
            <StudioDevicesTab
              devicesList={devices.devicesList}
              loadingDevices={devices.loadingDevices}
              isPairingOpen={devices.isPairingOpen}
              onTogglePairingOpen={() => devices.setIsPairingOpen(!devices.isPairingOpen)}
              pairCode={devices.pairCode}
              onPairCodeChange={devices.setPairCode}
              pairProfileId={devices.pairProfileId}
              onPairProfileIdChange={devices.setPairProfileId}
              pairDeviceName={devices.pairDeviceName}
              onPairDeviceNameChange={devices.setPairDeviceName}
              isSubmittingPair={devices.isSubmittingPair}
              pairError={devices.pairError}
              pairSuccess={devices.pairSuccess}
              onPairSubmit={devices.handlePairDevice}
              onUnpair={devices.handleUnpairDevice}
              deletingDeviceId={devices.deletingDeviceId}
              onRefresh={devices.fetchDevices}
              initialProfiles={initialProfiles}
            />
          )}

          {activeTab === 'analytics' && <StudioAnalyticsView />}

          {activeTab === 'settings' && (
            <StudioSecurityTab
              currentUser={currentUser}
              onSignOut={security.handleSignOut}
              passkeysList={security.passkeysList}
              loadingPasskeys={security.loadingPasskeys}
              isAddingPasskeyOpen={security.isAddingPasskeyOpen}
              onToggleAddingPasskeyOpen={() => security.setIsAddingPasskeyOpen(!security.isAddingPasskeyOpen)}
              newPasskeyName={security.newPasskeyName}
              onNewPasskeyNameChange={security.setNewPasskeyName}
              registeringPasskey={security.registeringPasskey}
              onRegisterPasskey={security.handleRegisterPasskey}
              onDeletePasskey={security.handleDeletePasskey}
              onRefreshPasskeys={security.fetchPasskeys}
              passkeyNotice={security.passkeyNotice}
              onDismissPasskeyNotice={() => security.setPasskeyNotice(null)}
              pinStatus={security.pinStatus}
              newPin={security.newPin}
              onNewPinChange={security.setNewPin}
              confirmPin={security.confirmPin}
              onConfirmPinChange={security.setConfirmPin}
              showPin={security.showPin}
              onToggleShowPin={() => security.setShowPin(!security.showPin)}
              isUpdatingPin={security.isUpdatingPin}
              onUpdatePin={security.handleUpdatePin}
              pinNotice={security.pinNotice}
              onDismissPinNotice={() => security.setPinNotice(null)}
              sessionsList={security.sessionsList}
              loadingSessions={security.loadingSessions}
              onRefreshSessions={security.fetchSessions}
              onRevokeSession={security.handleRevokeSession}
              onRevokeOtherSessions={security.handleRevokeOtherSessions}
              revokingSessionId={security.revokingSessionId}
            />
          )}
        </main>
      </div>

      <DeleteConfirmModal
        isOpen={modalConfig.isOpen}
        title={modalConfig.title}
        message={modalConfig.message}
        details={modalConfig.details}
        confirmLabel={modalConfig.confirmLabel}
        isDeleting={isModalProcessing}
        onConfirm={async () => {
          setIsModalProcessing(true);
          try {
            await modalConfig.action();
          } finally {
            setIsModalProcessing(false);
            setModalConfig((prev) => ({ ...prev, isOpen: false }));
          }
        }}
        onCancel={() => {
          if (!isModalProcessing) setModalConfig((prev) => ({ ...prev, isOpen: false }));
        }}
      />
    </div>
  );
};

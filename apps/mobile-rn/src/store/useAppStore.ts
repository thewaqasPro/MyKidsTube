import { create } from 'zustand';
import { VideoItem, CategoryItem, DownloadStatus } from '../types/video';
import { ChildProfile, LocalWatchEvent, WatchAnalytics } from '../types/profile';
import { databaseService } from '../services/DatabaseService';
import { vpsApiService } from '../services/VpsApiService';
import { downloadService } from '../services/DownloadService';
import { securityService } from '../services/SecurityService';
import { DEFAULT_VPS_URL, normalizeServerUrl } from '../utils/urlHelpers';

export interface AppState {
  isInitialized: boolean;
  isDevicePaired: boolean;
  pairingCode: string | null;
  deviceName: string;
  vpsUrl: string;

  // Catalog
  videos: VideoItem[];
  categories: CategoryItem[];
  activeCategoryId: string;
  activeVideo: VideoItem | null;
  favoriteVideoIds: string[];

  // Profiles
  profiles: ChildProfile[];
  activeProfile: ChildProfile | null;

  // State flags
  isSyncingCatalog: boolean;
  lastSyncTime: number | null;
  cachedBytes: number;
  freeSpaceBytes: number | null;

  // Prune Safety Cap Modal State
  pendingPrune: {
    toDeleteCount: number;
    totalCount: number;
    validIds: string[];
  } | null;

  // UI States
  isTouchLocked: boolean;
  orientationMode: 'auto' | 'portrait' | 'landscape';
  downloadProgress: Record<string, number>;

  // Actions
  initApp: () => Promise<void>;
  requestDevicePairing: (name?: string) => Promise<string | null>;
  checkPairingStatus: () => Promise<'paired' | 'expired' | 'pending'>;
  unpairDevice: () => Promise<void>;
  setVpsUrl: (url: string) => Promise<void>;

  syncCatalog: () => Promise<void>;
  confirmPrune: () => Promise<void>;
  cancelPrune: () => void;

  setActiveCategory: (catId: string) => void;
  setActiveVideo: (video: VideoItem | null) => void;
  toggleFavorite: (videoId: string) => Promise<boolean>;
  switchProfile: (profile: ChildProfile) => Promise<void>;

  downloadVideo: (video: VideoItem) => Promise<boolean>;
  cancelDownload: (videoId: string) => void;
  deleteDownloadedVideo: (video: VideoItem) => Promise<void>;
  downloadAllVideos: () => Promise<void>;
  deleteAllDownloadedVideos: () => Promise<void>;

  setTouchLocked: (locked: boolean) => void;
  setOrientationMode: (mode: 'auto' | 'portrait' | 'landscape') => void;
  refreshStorageStats: () => Promise<void>;

  recordWatchTime: (
    video: VideoItem,
    secondsWatched: number,
    completionRate: number,
    isCompleted: boolean,
    isSkipped: boolean
  ) => Promise<void>;
  syncWatchMetrics: () => Promise<void>;
  getWatchAnalytics: () => Promise<WatchAnalytics>;
}

export const useAppStore = create<AppState>((set, get) => ({
  isInitialized: false,
  isDevicePaired: false,
  pairingCode: null,
  deviceName: 'Kids Tablet',
  vpsUrl: DEFAULT_VPS_URL,

  videos: [],
  categories: [],
  activeCategoryId: 'all',
  activeVideo: null,
  favoriteVideoIds: [],

  profiles: [],
  activeProfile: null,

  isSyncingCatalog: false,
  lastSyncTime: null,
  cachedBytes: 0,
  freeSpaceBytes: null,

  pendingPrune: null,

  isTouchLocked: false,
  orientationMode: 'auto',
  downloadProgress: {},

  initApp: async () => {
    try {
      // 1. Initialize PIN & Security
      await securityService.initPinIfNeeded();
      const token = await securityService.getAuthToken();
      if (token) {
        vpsApiService.setAuthToken(token);
      }

      // 2. Load VPS URL from database settings
      const savedUrl = await databaseService.getSetting('vps_url');
      const vpsUrl = savedUrl ? normalizeServerUrl(savedUrl) : DEFAULT_VPS_URL;

      // 3. Load Pairing State
      const pairedSetting = await databaseService.getSetting('is_device_paired');
      const isDevicePaired = pairedSetting === 'true';

      // 4. Load Categories & Videos from SQLite
      const categories = await databaseService.getAllCategories();
      const videos = await databaseService.getAllVideos();
      const favoriteVideoIds = await databaseService.getFavoriteIds();

      // 5. Load Profiles
      let profiles = await databaseService.getLocalProfiles();
      let activeProfile: ChildProfile | null = null;
      const activeProfId = await databaseService.getSetting('current_profile_id');

      if (profiles.length > 0) {
        activeProfile =
          profiles.find((p) => p.id === activeProfId) || profiles[0];
      }

      // 6. Refresh storage
      const cachedBytes = await downloadService.getTotalCachedBytes();
      const freeSpaceBytes = await downloadService.getFreeDiskSpace();

      set({
        isInitialized: true,
        isDevicePaired,
        vpsUrl,
        categories,
        videos,
        favoriteVideoIds,
        profiles,
        activeProfile,
        cachedBytes,
        freeSpaceBytes,
      });

      // 7. Background sync if paired
      if (isDevicePaired) {
        get().syncCatalog();
      }
    } catch (e) {
      console.error('initApp error:', e);
      set({ isInitialized: true });
    }
  },

  requestDevicePairing: async (name: string = 'Kids Tablet') => {
    set({ deviceName: name, pairingCode: null });
    const { vpsUrl } = get();
    const res = await vpsApiService.registerDevice(vpsUrl, name);
    if (res && res.pairing_code) {
      set({ pairingCode: res.pairing_code });
      return res.pairing_code;
    }
    return null;
  },

  checkPairingStatus: async () => {
    const { pairingCode, vpsUrl } = get();
    if (!pairingCode) return 'expired';

    const res = await vpsApiService.checkDeviceStatus(vpsUrl, pairingCode);
    if (res) {
      if (res.status === 'paired') {
        await databaseService.setSetting('is_device_paired', 'true');
        if (res.auth_token) {
          await securityService.setAuthToken(res.auth_token);
          vpsApiService.setAuthToken(res.auth_token);
        }

        let activeProfile = get().activeProfile;
        if (res.profile) {
          const prof: ChildProfile = {
            id: String(res.profile.id),
            name: res.profile.name || 'Child',
            avatarIcon: res.profile.avatar_icon || 'bear',
            ageBracket: res.profile.age_bracket || 'all',
          };
          activeProfile = prof;
          await databaseService.upsertLocalProfile(prof);
          await databaseService.setSetting('current_profile_id', prof.id);
          await databaseService.setSetting('current_profile_name', prof.name);
          await databaseService.setSetting('current_profile_avatar', prof.avatarIcon);
        }

        set({
          isDevicePaired: true,
          activeProfile,
        });

        await get().syncCatalog();
        return 'paired';
      } else if (res.status === 'expired') {
        return 'expired';
      }
      return 'pending';
    }
    return 'pending';
  },

  unpairDevice: async () => {
    await databaseService.setSetting('is_device_paired', 'false');
    await securityService.clearAuthToken();
    vpsApiService.setAuthToken(null);
    set({
      isDevicePaired: false,
      pairingCode: null,
      activeProfile: null,
    });
  },

  setVpsUrl: async (url: string) => {
    const normalized = normalizeServerUrl(url);
    await databaseService.setSetting('vps_url', normalized);
    set({ vpsUrl: normalized });
    if (get().isDevicePaired) {
      get().syncCatalog();
    }
  },

  syncCatalog: async () => {
    if (get().isSyncingCatalog) return;
    set({ isSyncingCatalog: true });

    try {
      const { vpsUrl, activeProfile } = get();
      const res = await vpsApiService.fetchCatalog(
        vpsUrl,
        activeProfile?.id
      );

      if (res && res.videos) {
        const fetchedVideos: VideoItem[] = res.videos.map((raw: any) => ({
          id: String(raw.id),
          title: raw.title || 'Untitled Video',
          duration: raw.duration || 0,
          durationFormatted: raw.duration_formatted || '00:00',
          categoryId: raw.category_id || 'cartoons',
          sourceUrl: raw.source_url || '',
          streamUrl: raw.stream_url || '',
          thumbnailUrl: raw.thumbnail_url || '',
          channelName: raw.channel_name || undefined,
          channelIconUrl: raw.channel_icon_url || undefined,
          fileSizeBytes: raw.file_size_bytes || 0,
          quality: raw.quality || '720p',
          downloadStatus: DownloadStatus.notDownloaded,
          downloadProgress: 0.0,
          status: raw.status || 'pending_download',
          youtubeId: raw.youtube_id || undefined,
        }));

        const fetchedCategories: CategoryItem[] = (res.categories || []).map(
          (raw: any, index: number) => ({
            id: String(raw.id),
            name: raw.name || 'Category',
            icon: raw.icon || 'category',
            displayOrder: raw.display_order ?? index,
          })
        );

        // Batch upsert to database
        await databaseService.batchUpsertCatalog(fetchedVideos, fetchedCategories);

        // Check Prune Safety Cap:
        const validIds = fetchedVideos.map((v) => v.id);
        const allLocal = await databaseService.getAllVideos();
        const toDeleteCount = allLocal.filter((v) => !validIds.includes(v.id)).length;

        if (allLocal.length > 2 && toDeleteCount / allLocal.length > 0.5) {
          // More than 50% videos missing! Set pendingPrune for confirmation modal
          set({
            pendingPrune: {
              toDeleteCount,
              totalCount: allLocal.length,
              validIds,
            },
          });
        } else {
          // Safe prune (<= 50%)
          await databaseService.pruneRemovedVideos(validIds, {
            allowEmpty: false,
            maxPruneRatio: 0.5,
          });
        }

        // Fetch refreshed categories and videos from DB
        const categories = await databaseService.getAllCategories();
        const videos = await databaseService.getAllVideos();
        const profiles = await vpsApiService.fetchProfiles(vpsUrl);
        for (const p of profiles) {
          await databaseService.upsertLocalProfile(p);
        }

        set({
          categories,
          videos,
          profiles: profiles.length > 0 ? profiles : get().profiles,
          lastSyncTime: Date.now(),
        });
      }
    } catch (e) {
      console.error('syncCatalog error:', e);
    } finally {
      set({ isSyncingCatalog: false });
      get().refreshStorageStats();
      get().syncWatchMetrics();
    }
  },

  confirmPrune: async () => {
    const { pendingPrune } = get();
    if (!pendingPrune) return;

    await databaseService.pruneRemovedVideos(pendingPrune.validIds, {
      allowEmpty: true,
      maxPruneRatio: 1.0,
      force: true,
    });

    const videos = await databaseService.getAllVideos();
    set({
      pendingPrune: null,
      videos,
    });
    get().refreshStorageStats();
  },

  cancelPrune: () => {
    set({ pendingPrune: null });
  },

  setActiveCategory: (catId: string) => {
    set({ activeCategoryId: catId });
  },

  setActiveVideo: (video: VideoItem | null) => {
    set({ activeVideo: video });
  },

  toggleFavorite: async (videoId: string) => {
    const isFav = await databaseService.toggleFavorite(videoId);
    const favoriteVideoIds = await databaseService.getFavoriteIds();
    set({ favoriteVideoIds });
    return isFav;
  },

  switchProfile: async (profile: ChildProfile) => {
    await databaseService.setSetting('current_profile_id', profile.id);
    await databaseService.setSetting('current_profile_name', profile.name);
    await databaseService.setSetting('current_profile_avatar', profile.avatarIcon);
    set({ activeProfile: profile });
    get().syncCatalog();
  },

  downloadVideo: async (video: VideoItem) => {
    const success = await downloadService.downloadVideo(video, (id, progress) => {
      set((state) => ({
        downloadProgress: {
          ...state.downloadProgress,
          [id]: progress,
        },
      }));
    });

    if (success) {
      // Reload videos to reflect status change
      const videos = await databaseService.getAllVideos();
      set({ videos });
    }
    return success;
  },

  cancelDownload: (videoId: string) => {
    downloadService.cancelDownload(videoId);
    set((state) => {
      const nextProgress = { ...state.downloadProgress };
      delete nextProgress[videoId];
      return { downloadProgress: nextProgress };
    });
    databaseService.getAllVideos().then((videos) => set({ videos }));
  },

  deleteDownloadedVideo: async (video: VideoItem) => {
    await downloadService.deleteDownloadedFile(video.id, video.localFilePath);
    const videos = await databaseService.getAllVideos();
    const cachedBytes = await downloadService.getTotalCachedBytes();
    set({ videos, cachedBytes });
  },

  downloadAllVideos: async () => {
    const { videos } = get();
    for (const v of videos) {
      if (v.downloadStatus !== DownloadStatus.downloaded && v.streamUrl) {
        await get().downloadVideo(v);
      }
    }
  },

  deleteAllDownloadedVideos: async () => {
    await downloadService.deleteAllDownloadedMedia();
    const videos = await databaseService.getAllVideos();
    const cachedBytes = await downloadService.getTotalCachedBytes();
    set({ videos, cachedBytes });
  },

  setTouchLocked: (locked: boolean) => {
    set({ isTouchLocked: locked });
  },

  setOrientationMode: (mode: 'auto' | 'portrait' | 'landscape') => {
    set({ orientationMode: mode });
  },

  refreshStorageStats: async () => {
    const cachedBytes = await downloadService.getTotalCachedBytes();
    const freeSpaceBytes = await downloadService.getFreeDiskSpace();
    set({ cachedBytes, freeSpaceBytes });
  },

  recordWatchTime: async (
    video: VideoItem,
    secondsWatched: number,
    completionRate: number,
    isCompleted: boolean,
    isSkipped: boolean
  ) => {
    if (secondsWatched <= 0) return;
    const { activeProfile, deviceName } = get();
    await databaseService.recordWatchEvent({
      videoId: video.id,
      videoTitle: video.title,
      categoryId: video.categoryId,
      deviceId: deviceName,
      profileId: activeProfile?.id,
      profileName: activeProfile?.name,
      secondsWatched,
      videoDuration: video.duration,
      completionRate,
      isCompleted,
      isSkipped,
      watchedAt: Date.now(),
    });
  },

  syncWatchMetrics: async () => {
    const { vpsUrl } = get();
    const pending = await databaseService.getPendingWatchEvents();
    if (pending.length === 0) return;

    const payload = pending.map((e) => ({
      video_id: e.videoId,
      video_title: e.videoTitle,
      category_id: e.categoryId,
      device_id: e.deviceId,
      profile_id: e.profileId,
      profile_name: e.profileName,
      seconds_watched: e.secondsWatched,
      video_duration: e.videoDuration,
      completion_rate: e.completionRate,
      is_completed: e.isCompleted,
      is_skipped: e.isSkipped,
      watched_at: e.watchedAt,
    }));

    const res = await vpsApiService.syncWatchEvents(vpsUrl, payload);
    if (res && res.success) {
      await databaseService.markWatchEventsSynced(pending.map((e) => e.id));
    }
  },

  getWatchAnalytics: async () => {
    const { activeProfile } = get();
    return await databaseService.getWatchAnalytics(activeProfile?.id);
  },
}));

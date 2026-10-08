import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { databaseService } from '../services/DatabaseService';
import { KidColors } from '../theme/colors';
import { VideoItem, DownloadStatus } from '../types/video';
import { formatBytes } from '../utils/urlHelpers';

type Props = NativeStackScreenProps<RootStackParamList, 'ParentStorage'>;

export const ParentStorageScreen: React.FC<Props> = ({ navigation }) => {
  const {
    cachedBytes,
    freeSpaceBytes,
    refreshStorageStats,
    downloadAllVideos,
    deleteAllDownloadedVideos,
    deleteDownloadedVideo,
    videos,
  } = useAppStore();

  const [downloadedList, setDownloadedList] = useState<VideoItem[]>([]);
  const [isDownloadingAll, setIsDownloadingAll] = useState(false);
  const [isClearing, setIsClearing] = useState(false);

  useEffect(() => {
    loadDownloadedVideos();
    refreshStorageStats();
  }, [videos]);

  const loadDownloadedVideos = async () => {
    const list = await databaseService.getDownloadedVideos();
    setDownloadedList(list);
  };

  const handleDownloadAll = async () => {
    Alert.alert(
      'Download All Videos',
      'Download all videos in the catalog for offline road-trip playback? This will download up to 2 videos concurrently.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Start Download',
          onPress: async () => {
            setIsDownloadingAll(true);
            await downloadAllVideos();
            setIsDownloadingAll(false);
            loadDownloadedVideos();
            refreshStorageStats();
          },
        },
      ]
    );
  };

  const handleClearAll = () => {
    Alert.alert(
      'Clear All Offline Media',
      'This will delete all downloaded videos and thumbnails from this tablet. Catalog items will remain streamable.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete All Files',
          style: 'destructive',
          onPress: async () => {
            setIsClearing(true);
            await deleteAllDownloadedVideos();
            await loadDownloadedVideos();
            await refreshStorageStats();
            setIsClearing(false);
          },
        },
      ]
    );
  };

  const totalDeviceSpace = (freeSpaceBytes || 0) + cachedBytes;
  const usedRatio = totalDeviceSpace > 0 ? cachedBytes / totalDeviceSpace : 0;

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          style={styles.backButton}
        >
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Storage & Downloads</Text>
        <View style={{ width: 44 }} />
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Storage Gauge Card */}
        <View style={styles.gaugeCard}>
          <Text style={styles.cardHeading}>Device Storage Usage</Text>
          <View style={styles.statsRow}>
            <View>
              <Text style={styles.statLabel}>Kids Media Used</Text>
              <Text style={styles.statValue}>{formatBytes(cachedBytes)}</Text>
            </View>
            <View style={{ alignItems: 'flex-end' }}>
              <Text style={styles.statLabel}>Free Device Space</Text>
              <Text style={styles.statValue}>
                {freeSpaceBytes ? formatBytes(freeSpaceBytes) : 'Calculating...'}
              </Text>
            </View>
          </View>

          {/* Visual Gauge Bar */}
          <View style={styles.gaugeBarTrack}>
            <View
              style={[
                styles.gaugeBarFill,
                { width: `${Math.max(4, Math.round(usedRatio * 100))}%` },
              ]}
            />
          </View>
          <Text style={styles.gaugeSub}>
            Offline files are stored securely in sandbox and excluded from OS cloud backup.
          </Text>
        </View>

        {/* Action Buttons */}
        <View style={styles.actionButtonsRow}>
          <TouchableOpacity
            disabled={isDownloadingAll}
            onPress={handleDownloadAll}
            style={[styles.btn, styles.downloadAllBtn]}
          >
            {isDownloadingAll ? (
              <ActivityIndicator size="small" color={KidColors.bgDark} />
            ) : (
              <Text style={styles.downloadAllText}>⬇️ Download All ({videos.length})</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            disabled={isClearing}
            onPress={handleClearAll}
            style={[styles.btn, styles.clearAllBtn]}
          >
            {isClearing ? (
              <ActivityIndicator size="small" color="#EF4444" />
            ) : (
              <Text style={styles.clearAllText}>🗑️ Clear Cache</Text>
            )}
          </TouchableOpacity>
        </View>

        {/* Downloaded Videos List */}
        <Text style={styles.sectionTitle}>
          Downloaded Offline Videos ({downloadedList.length})
        </Text>

        {downloadedList.length === 0 ? (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyText}>
              No videos currently downloaded for offline play. Tap "Download All" above or download individual tiles from home.
            </Text>
          </View>
        ) : (
          <View style={styles.downloadedList}>
            {downloadedList.map((item) => (
              <View key={item.id} style={styles.downloadedItem}>
                <View style={styles.itemTextCol}>
                  <Text numberOfLines={1} style={styles.itemTitle}>
                    {item.title}
                  </Text>
                  <Text style={styles.itemMeta}>
                    {item.fileSizeBytes > 0
                      ? formatBytes(item.fileSizeBytes)
                      : 'Downloaded MP4'}{' '}
                    • {item.durationFormatted}
                  </Text>
                </View>
                <TouchableOpacity
                  onPress={() => deleteDownloadedVideo(item)}
                  style={styles.itemDeleteBtn}
                >
                  <Text style={{ fontSize: 16 }}>🗑️</Text>
                </TouchableOpacity>
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: KidColors.bgDark,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderColor: KidColors.borderDark,
  },
  backButton: {
    padding: 6,
  },
  backText: {
    color: KidColors.sky,
    fontWeight: '700',
    fontSize: 15,
  },
  headerTitle: {
    color: KidColors.textLight,
    fontSize: 18,
    fontWeight: '800',
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 40,
  },
  gaugeCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 22,
    padding: 20,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
    marginBottom: 20,
  },
  cardHeading: {
    color: KidColors.textLight,
    fontSize: 17,
    fontWeight: '800',
    marginBottom: 16,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 14,
  },
  statLabel: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '600',
    marginBottom: 4,
  },
  statValue: {
    color: KidColors.textLight,
    fontSize: 18,
    fontWeight: '800',
  },
  gaugeBarTrack: {
    height: 10,
    backgroundColor: KidColors.bgDark,
    borderRadius: 5,
    overflow: 'hidden',
    marginBottom: 12,
  },
  gaugeBarFill: {
    height: '100%',
    backgroundColor: KidColors.mint,
    borderRadius: 5,
  },
  gaugeSub: {
    color: KidColors.textTertiary,
    fontSize: 11,
    lineHeight: 15,
  },
  actionButtonsRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 24,
  },
  btn: {
    flex: 1,
    height: 48,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  downloadAllBtn: {
    backgroundColor: KidColors.sky,
  },
  downloadAllText: {
    color: KidColors.bgDark,
    fontWeight: '800',
    fontSize: 14,
  },
  clearAllBtn: {
    backgroundColor: 'rgba(239, 68, 68, 0.12)',
    borderWidth: 1,
    borderColor: 'rgba(239, 68, 68, 0.4)',
  },
  clearAllText: {
    color: '#EF4444',
    fontWeight: '800',
    fontSize: 14,
  },
  sectionTitle: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 12,
  },
  emptyCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 18,
    padding: 24,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    alignItems: 'center',
  },
  emptyText: {
    color: KidColors.textMuted,
    fontSize: 13,
    textAlign: 'center',
    lineHeight: 18,
  },
  downloadedList: {
    gap: 10,
  },
  downloadedItem: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 16,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  itemTextCol: {
    flex: 1,
    marginRight: 10,
  },
  itemTitle: {
    color: KidColors.textLight,
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 4,
  },
  itemMeta: {
    color: KidColors.textMuted,
    fontSize: 12,
  },
  itemDeleteBtn: {
    padding: 8,
  },
});

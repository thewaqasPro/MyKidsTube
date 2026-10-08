import React from 'react';
import {
  View,
  Text,
  Image,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { VideoItem, DownloadStatus } from '../types/video';
import { KidColors } from '../theme/colors';
import {
  getThumbnailUrl,
  formatDuration,
} from '../utils/urlHelpers';
import { useAppStore } from '../store/useAppStore';

interface Props {
  video: VideoItem;
  onPress: () => void;
  vpsUrl?: string;
}

export const VideoCard: React.FC<Props> = ({ video, onPress, vpsUrl }) => {
  const {
    favoriteVideoIds,
    toggleFavorite,
    downloadVideo,
    cancelDownload,
    downloadProgress,
  } = useAppStore();

  const isFavorite = favoriteVideoIds.includes(video.id);
  const currentProgress = downloadProgress[video.id] ?? video.downloadProgress;
  const isDownloading = video.downloadStatus === DownloadStatus.downloading;
  const isDownloaded = video.downloadStatus === DownloadStatus.downloaded && !!video.localFilePath;

  const thumbUrl = getThumbnailUrl(video, vpsUrl);

  const handleDownloadPress = () => {
    if (isDownloading) {
      cancelDownload(video.id);
    } else if (!isDownloaded) {
      downloadVideo(video);
    }
  };

  return (
    <TouchableOpacity
      activeOpacity={0.88}
      onPress={onPress}
      style={styles.card}
    >
      {/* 16:9 Thumbnail Area */}
      <View style={styles.thumbnailContainer}>
        <Image
          source={{ uri: thumbUrl }}
          style={styles.thumbnail}
          resizeMode="cover"
        />

        {/* Offline / Verified Safe Badge */}
        {isDownloaded ? (
          <View style={[styles.badge, styles.badgeOffline]}>
            <Text style={styles.badgeText}>✓ Offline</Text>
          </View>
        ) : video.status === 'ready' ? (
          <View style={[styles.badge, styles.badgeVerified]}>
            <Text style={styles.badgeText}>Verified</Text>
          </View>
        ) : null}

        {/* Duration Badge */}
        <View style={styles.durationBadge}>
          <Text style={styles.durationText}>
            {formatDuration(video.duration)}
          </Text>
        </View>

        {/* Download Progress Bar */}
        {isDownloading && (
          <View style={styles.progressBarContainer}>
            <View
              style={[
                styles.progressBarFill,
                { width: `${Math.round(currentProgress * 100)}%` },
              ]}
            />
          </View>
        )}
      </View>

      {/* Info & Actions */}
      <View style={styles.infoRow}>
        <View style={styles.titleContainer}>
          <Text numberOfLines={2} style={styles.titleText}>
            {video.title}
          </Text>
          <Text numberOfLines={1} style={styles.channelText}>
            {video.channelName || 'Safe Kids TV'}
          </Text>
        </View>

        <View style={styles.actionsContainer}>
          {/* Favorite Toggle */}
          <TouchableOpacity
            hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
            onPress={() => toggleFavorite(video.id)}
            style={styles.iconButton}
          >
            <Text style={{ fontSize: 18 }}>
              {isFavorite ? '❤️' : '🤍'}
            </Text>
          </TouchableOpacity>

          {/* Download Action */}
          <TouchableOpacity
            hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
            onPress={handleDownloadPress}
            style={[
              styles.downloadButton,
              isDownloaded ? styles.downloadButtonDone : styles.downloadButtonAction,
            ]}
          >
            {isDownloading ? (
              <ActivityIndicator size="small" color={KidColors.accent} />
            ) : isDownloaded ? (
              <Text style={{ fontSize: 13, color: KidColors.mint, fontWeight: '800' }}>✓</Text>
            ) : (
              <Text style={{ fontSize: 13, color: KidColors.sky, fontWeight: '800' }}>⬇</Text>
            )}
          </TouchableOpacity>
        </View>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 18,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
    overflow: 'hidden',
    marginBottom: 16,
  },
  thumbnailContainer: {
    width: '100%',
    aspectRatio: 16 / 9,
    backgroundColor: KidColors.surfaceDark,
    position: 'relative',
  },
  thumbnail: {
    width: '100%',
    height: '100%',
  },
  badge: {
    position: 'absolute',
    top: 10,
    left: 10,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
  },
  badgeOffline: {
    backgroundColor: 'rgba(16, 185, 129, 0.9)',
  },
  badgeVerified: {
    backgroundColor: 'rgba(56, 189, 248, 0.85)',
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0.2,
  },
  durationBadge: {
    position: 'absolute',
    bottom: 8,
    right: 8,
    backgroundColor: KidColors.durationBadgeBg,
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: 6,
  },
  durationText: {
    color: KidColors.textLight,
    fontSize: 11,
    fontWeight: '700',
  },
  progressBarContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: KidColors.primary,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
  },
  titleContainer: {
    flex: 1,
    marginRight: 8,
  },
  titleText: {
    color: KidColors.textLight,
    fontSize: 15,
    fontWeight: '700',
    lineHeight: 20,
    marginBottom: 4,
  },
  channelText: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '500',
  },
  actionsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  iconButton: {
    padding: 6,
  },
  downloadButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  downloadButtonAction: {
    backgroundColor: KidColors.cardElevated,
    borderColor: KidColors.borderDark,
  },
  downloadButtonDone: {
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    borderColor: KidColors.mint,
  },
});

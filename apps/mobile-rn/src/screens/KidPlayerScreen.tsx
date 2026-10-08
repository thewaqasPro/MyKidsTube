import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  BackHandler,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import Video, { VideoRef } from 'react-native-video';
import { useKeepAwake } from 'expo-keep-awake';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { KidColors } from '../theme/colors';
import { KidEmbedPlayer } from '../components/KidEmbedPlayer';
import { TouchLockOverlay } from '../components/TouchLockOverlay';
import { OrientationModeSwitch } from '../components/OrientationModeSwitch';
import { VideoTile } from '../components/VideoTile';
import { getStreamUrl, getYoutubeId } from '../utils/urlHelpers';
import { DownloadStatus } from '../types/video';

type Props = NativeStackScreenProps<RootStackParamList, 'KidPlayer'>;

export const KidPlayerScreen: React.FC<Props> = ({ route, navigation }) => {
  useKeepAwake();

  const { videoId } = route.params;
  const {
    videos,
    favoriteVideoIds,
    toggleFavorite,
    downloadVideo,
    cancelDownload,
    isTouchLocked,
    setTouchLocked,
    recordWatchTime,
    vpsUrl,
  } = useAppStore();

  const [activeVideoId, setActiveVideoId] = useState(videoId);
  const [isPlaying, setIsPlaying] = useState(true);
  const [useEmbedFallback, setUseEmbedFallback] = useState(false);

  // Watch time tracking
  const watchSecondsRef = useRef(0);
  const watchTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const durationRef = useRef(0);

  const videoRef = useRef<VideoRef>(null);

  const currentVideo = videos.find((v) => v.id === activeVideoId) || videos[0];

  useEffect(() => {
    setActiveVideoId(videoId);
    setUseEmbedFallback(false);
  }, [videoId]);

  useEffect(() => {
    // Start watch time tracker
    watchSecondsRef.current = 0;
    if (currentVideo) {
      durationRef.current = currentVideo.duration || 0;
    }

    watchTimerRef.current = setInterval(() => {
      if (isPlaying) {
        watchSecondsRef.current += 1;
      }
    }, 1000);

    return () => {
      if (watchTimerRef.current) {
        clearInterval(watchTimerRef.current);
      }
      // Record watch time on exit
      if (currentVideo && watchSecondsRef.current > 0) {
        const dur = durationRef.current > 0 ? durationRef.current : 60;
        const rate = Math.min(watchSecondsRef.current / dur, 1.0);
        recordWatchTime(
          currentVideo,
          watchSecondsRef.current,
          rate,
          rate >= 0.8,
          rate < 0.2
        );
      }
    };
  }, [activeVideoId, isPlaying]);

  useEffect(() => {
    const backAction = () => {
      if (isTouchLocked) {
        return true; // Block hardware back while touch locked
      }
      return false;
    };
    const backHandler = BackHandler.addEventListener(
      'hardwareBackPress',
      backAction
    );
    return () => backHandler.remove();
  }, [isTouchLocked]);

  if (!currentVideo) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>Video not found.</Text>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          style={styles.backButton}
        >
          <Text style={styles.backButtonText}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const isFavorite = favoriteVideoIds.includes(currentVideo.id);
  const isDownloaded =
    currentVideo.downloadStatus === DownloadStatus.downloaded &&
    !!currentVideo.localFilePath;
  const isDownloading =
    currentVideo.downloadStatus === DownloadStatus.downloading;

  const streamUri = getStreamUrl(currentVideo);
  const youtubeId = getYoutubeId(currentVideo);

  // Play native if local MP4 exists or server MP4 ready, else fallback to embed
  const canPlayNative =
    !useEmbedFallback &&
    (isDownloaded || (currentVideo.status === 'ready' && streamUri.length > 0));

  const relatedVideos = videos.filter((v) => v.id !== currentVideo.id);

  const handleVideoEnded = () => {
    if (currentVideo) {
      recordWatchTime(
        currentVideo,
        watchSecondsRef.current,
        1.0,
        true,
        false
      );
    }
    // Auto-advance to next related video
    if (relatedVideos.length > 0) {
      setActiveVideoId(relatedVideos[0].id);
      setUseEmbedFallback(false);
    }
  };

  return (
    <View style={styles.container}>
      {/* Video Viewport (16:9) */}
      <View style={styles.playerContainer}>
        {canPlayNative ? (
          <Video
            ref={videoRef}
            source={{ uri: streamUri }}
            style={styles.videoPlayer}
            controls={!isTouchLocked}
            paused={!isPlaying}
            resizeMode="contain"
            onError={(err) => {
              console.warn('Native video error, switching to embed fallback:', err);
              setUseEmbedFallback(true);
            }}
            onEnd={handleVideoEnded}
          />
        ) : (
          <KidEmbedPlayer
            youtubeId={youtubeId}
            autoplay={true}
            onEnded={handleVideoEnded}
          />
        )}
      </View>

      {/* Controls & Details */}
      <ScrollView contentContainerStyle={styles.detailsContent}>
        {/* Top Action Bar */}
        <View style={styles.topBar}>
          <TouchableOpacity
            disabled={isTouchLocked}
            onPress={() => navigation.goBack()}
            style={styles.backBtn}
          >
            <Text style={styles.backBtnText}>← Back</Text>
          </TouchableOpacity>

          <View style={styles.rightActions}>
            {/* Orientation mode switch */}
            <OrientationModeSwitch />

            {/* Toddler Touch Lock Button */}
            <TouchableOpacity
              onPress={() => setTouchLocked(true)}
              style={styles.lockBtn}
            >
              <Text style={{ fontSize: 18 }}>🔒</Text>
              <Text style={styles.lockBtnText}>Lock</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Video Title & Meta */}
        <View style={styles.titleSection}>
          <Text style={styles.videoTitle}>{currentVideo.title}</Text>
          <View style={styles.metaRow}>
            <Text style={styles.channelName}>
              {currentVideo.channelName || 'Safe Kids TV'}
            </Text>
            <Text style={styles.metaDot}>•</Text>
            <Text style={styles.metaDuration}>
              {currentVideo.durationFormatted}
            </Text>

            {isDownloaded && (
              <View style={styles.offlineBadge}>
                <Text style={styles.offlineBadgeText}>✓ Offline Ready</Text>
              </View>
            )}
          </View>
        </View>

        {/* Action Row: Favorite & Download */}
        <View style={styles.actionRow}>
          <TouchableOpacity
            disabled={isTouchLocked}
            onPress={() => toggleFavorite(currentVideo.id)}
            style={styles.pillActionBtn}
          >
            <Text style={{ fontSize: 18, marginRight: 6 }}>
              {isFavorite ? '❤️' : '🤍'}
            </Text>
            <Text style={styles.pillActionText}>
              {isFavorite ? 'Favorited' : 'Favorite'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            disabled={isTouchLocked}
            onPress={() => {
              if (isDownloading) {
                cancelDownload(currentVideo.id);
              } else if (!isDownloaded) {
                downloadVideo(currentVideo);
              }
            }}
            style={styles.pillActionBtn}
          >
            <Text style={{ fontSize: 18, marginRight: 6 }}>
              {isDownloaded ? '✓' : isDownloading ? '⏳' : '⬇️'}
            </Text>
            <Text style={styles.pillActionText}>
              {isDownloaded
                ? 'Downloaded'
                : isDownloading
                ? 'Downloading...'
                : 'Download'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Related Videos / Up Next */}
        <Text style={styles.upNextTitle}>Up Next for You</Text>
        <View style={styles.relatedList}>
          {relatedVideos.map((video) => (
            <VideoTile
              key={video.id}
              video={video}
              vpsUrl={vpsUrl}
              onPress={() => {
                if (!isTouchLocked) {
                  setActiveVideoId(video.id);
                  setUseEmbedFallback(false);
                }
              }}
            />
          ))}
        </View>
      </ScrollView>

      {/* Toddler Touch Lock Fullscreen Overlay */}
      <TouchLockOverlay
        isLocked={isTouchLocked}
        onUnlock={() => setTouchLocked(false)}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: KidColors.bgDark,
  },
  playerContainer: {
    width: '100%',
    aspectRatio: 16 / 9,
    backgroundColor: '#000',
  },
  videoPlayer: {
    width: '100%',
    height: '100%',
  },
  detailsContent: {
    padding: 16,
    paddingBottom: 40,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  backBtn: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 14,
    backgroundColor: KidColors.cardElevated,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  backBtnText: {
    color: KidColors.sky,
    fontWeight: '800',
    fontSize: 13,
  },
  rightActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  lockBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: KidColors.cardElevated,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: KidColors.accent,
    gap: 4,
  },
  lockBtnText: {
    color: KidColors.accent,
    fontWeight: '800',
    fontSize: 12,
  },
  titleSection: {
    marginBottom: 16,
  },
  videoTitle: {
    color: KidColors.textLight,
    fontSize: 18,
    fontWeight: '800',
    lineHeight: 24,
    marginBottom: 6,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 6,
  },
  channelName: {
    color: KidColors.textMuted,
    fontSize: 13,
    fontWeight: '600',
  },
  metaDot: {
    color: KidColors.textTertiary,
    fontSize: 13,
  },
  metaDuration: {
    color: KidColors.textTertiary,
    fontSize: 13,
  },
  offlineBadge: {
    backgroundColor: 'rgba(16, 185, 129, 0.2)',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: KidColors.mint,
    marginLeft: 6,
  },
  offlineBadgeText: {
    color: KidColors.mint,
    fontSize: 11,
    fontWeight: '700',
  },
  actionRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 24,
  },
  pillActionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: KidColors.cardDark,
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
  },
  pillActionText: {
    color: KidColors.textLight,
    fontWeight: '700',
    fontSize: 13,
  },
  upNextTitle: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 12,
  },
  relatedList: {
    gap: 4,
  },
  errorContainer: {
    flex: 1,
    backgroundColor: KidColors.bgDark,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  errorText: {
    color: KidColors.textLight,
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 16,
  },
  backButton: {
    backgroundColor: KidColors.primary,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 14,
  },
  backButtonText: {
    color: '#FFF',
    fontWeight: '800',
    fontSize: 14,
  },
});

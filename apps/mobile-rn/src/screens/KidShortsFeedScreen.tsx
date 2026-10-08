import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Dimensions,
  FlatList,
  ViewToken,
  BackHandler,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import Video from 'react-native-video';
import { useKeepAwake } from 'expo-keep-awake';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { KidEmbedPlayer } from '../components/KidEmbedPlayer';
import { ShortsActionRail } from '../components/ShortsActionRail';
import { TouchLockOverlay } from '../components/TouchLockOverlay';
import { isVideoShort, getStreamUrl, getYoutubeId } from '../utils/urlHelpers';
import { DownloadStatus, VideoItem } from '../types/video';

type Props = NativeStackScreenProps<RootStackParamList, 'KidShortsFeed'>;

const { height: WINDOW_HEIGHT, width: WINDOW_WIDTH } = Dimensions.get('window');

export const KidShortsFeedScreen: React.FC<Props> = ({ route, navigation }) => {
  useKeepAwake();

  const initialVideoId = route.params?.initialVideoId;
  const {
    videos,
    favoriteVideoIds,
    toggleFavorite,
    isTouchLocked,
    setTouchLocked,
    recordWatchTime,
  } = useAppStore();

  const shorts = videos.filter((v) => isVideoShort(v));
  // If no authentic shorts found in catalog, fallback to all videos
  const feedItems = shorts.length > 0 ? shorts : videos;

  const [activeIndex, setActiveIndex] = useState(0);
  const [isMuted, setIsMuted] = useState(false);

  // Watch time tracker
  const watchSecondsRef = useRef(0);
  const watchTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (initialVideoId) {
      const idx = feedItems.findIndex((v) => v.id === initialVideoId);
      if (idx !== -1) {
        setActiveIndex(idx);
      }
    }
  }, [initialVideoId]);

  useEffect(() => {
    watchSecondsRef.current = 0;
    watchTimerRef.current = setInterval(() => {
      watchSecondsRef.current += 1;
    }, 1000);

    return () => {
      if (watchTimerRef.current) {
        clearInterval(watchTimerRef.current);
      }
      const currentShort = feedItems[activeIndex];
      if (currentShort && watchSecondsRef.current > 0) {
        recordWatchTime(
          currentShort,
          watchSecondsRef.current,
          1.0,
          true,
          false
        );
      }
    };
  }, [activeIndex]);

  useEffect(() => {
    const backAction = () => {
      if (isTouchLocked) {
        return true; // Block hardware back while toddler lock is active
      }
      return false;
    };
    const backHandler = BackHandler.addEventListener(
      'hardwareBackPress',
      backAction
    );
    return () => backHandler.remove();
  }, [isTouchLocked]);

  const onViewableItemsChanged = useRef(
    ({ viewableItems }: { viewableItems: ViewToken[] }) => {
      if (viewableItems.length > 0 && viewableItems[0].index !== null) {
        setActiveIndex(viewableItems[0].index);
      }
    }
  ).current;

  const viewabilityConfig = useRef({
    itemVisiblePercentThreshold: 70,
  }).current;

  const renderShortItem = ({ item, index }: { item: VideoItem; index: number }) => {
    const isActive = index === activeIndex;
    const isDownloaded =
      item.downloadStatus === DownloadStatus.downloaded && !!item.localFilePath;
    const streamUri = getStreamUrl(item);
    const youtubeId = getYoutubeId(item);

    const isNativeReady = isDownloaded || (item.status === 'ready' && streamUri.length > 0);

    return (
      <View style={styles.pageContainer}>
        {isActive ? (
          isNativeReady ? (
            <Video
              source={{ uri: streamUri }}
              style={styles.fullVideo}
              resizeMode="cover"
              repeat={true}
              muted={isMuted}
              paused={!isActive}
            />
          ) : (
            <KidEmbedPlayer
              youtubeId={youtubeId}
              autoplay={true}
              style={styles.embedFill}
            />
          )
        ) : (
          <View style={styles.idlePage} />
        )}

        {/* Bottom Title & Channel Info */}
        <View style={styles.bottomInfo}>
          <Text numberOfLines={2} style={styles.titleText}>
            {item.title}
          </Text>
          <Text style={styles.channelText}>
            {item.channelName || 'Safe Kids TV'}
          </Text>
        </View>

        {/* Right Action Rail */}
        <ShortsActionRail
          isFavorite={favoriteVideoIds.includes(item.id)}
          isMuted={isMuted}
          onToggleFavorite={() => toggleFavorite(item.id)}
          onToggleMute={() => setIsMuted(!isMuted)}
          onLockTouch={() => setTouchLocked(true)}
          onClose={() => navigation.goBack()}
        />
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <FlatList
        data={feedItems}
        renderItem={renderShortItem}
        keyExtractor={(item) => item.id}
        pagingEnabled
        showsVerticalScrollIndicator={false}
        snapToInterval={WINDOW_HEIGHT}
        snapToAlignment="start"
        decelerationRate="fast"
        onViewableItemsChanged={onViewableItemsChanged}
        viewabilityConfig={viewabilityConfig}
        scrollEnabled={!isTouchLocked}
      />

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
    backgroundColor: '#000',
  },
  pageContainer: {
    width: WINDOW_WIDTH,
    height: WINDOW_HEIGHT,
    position: 'relative',
    backgroundColor: '#000',
    justifyContent: 'center',
    alignItems: 'center',
  },
  fullVideo: {
    width: '100%',
    height: '100%',
  },
  embedFill: {
    width: '100%',
    height: '100%',
    aspectRatio: undefined,
  },
  idlePage: {
    width: '100%',
    height: '100%',
    backgroundColor: '#05070D',
  },
  bottomInfo: {
    position: 'absolute',
    left: 16,
    right: 80,
    bottom: 40,
    zIndex: 40,
  },
  titleText: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '800',
    lineHeight: 22,
    marginBottom: 6,
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 4,
  },
  channelText: {
    color: 'rgba(255, 255, 255, 0.8)',
    fontSize: 13,
    fontWeight: '600',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 3,
  },
});

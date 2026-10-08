import React from 'react';
import { View, Text, Image, StyleSheet, TouchableOpacity } from 'react-native';
import { VideoItem } from '../types/video';
import { KidColors } from '../theme/colors';
import { getThumbnailUrl, formatDuration } from '../utils/urlHelpers';

interface Props {
  video: VideoItem;
  onPress: () => void;
  vpsUrl?: string;
  isActive?: boolean;
}

export const VideoTile: React.FC<Props> = ({
  video,
  onPress,
  vpsUrl,
  isActive = false,
}) => {
  const thumbUrl = getThumbnailUrl(video, vpsUrl);

  return (
    <TouchableOpacity
      activeOpacity={0.8}
      onPress={onPress}
      style={[
        styles.container,
        isActive && styles.activeContainer,
      ]}
    >
      <View style={styles.thumbWrapper}>
        <Image
          source={{ uri: thumbUrl }}
          style={styles.thumbnail}
          resizeMode="cover"
        />
        <View style={styles.durationBadge}>
          <Text style={styles.durationText}>
            {formatDuration(video.duration)}
          </Text>
        </View>
      </View>
      <View style={styles.details}>
        <Text
          numberOfLines={2}
          style={[styles.title, isActive && { color: KidColors.sky }]}
        >
          {video.title}
        </Text>
        <Text numberOfLines={1} style={styles.channel}>
          {video.channelName || 'Safe Kids TV'}
        </Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    padding: 10,
    borderRadius: 14,
    backgroundColor: KidColors.cardDark,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    marginBottom: 10,
    alignItems: 'center',
  },
  activeContainer: {
    borderColor: KidColors.sky,
    backgroundColor: KidColors.cardElevated,
  },
  thumbWrapper: {
    width: 110,
    height: 65,
    borderRadius: 8,
    overflow: 'hidden',
    position: 'relative',
    backgroundColor: KidColors.surfaceDark,
  },
  thumbnail: {
    width: '100%',
    height: '100%',
  },
  durationBadge: {
    position: 'absolute',
    bottom: 4,
    right: 4,
    backgroundColor: KidColors.durationBadgeBg,
    paddingHorizontal: 4,
    paddingVertical: 2,
    borderRadius: 4,
  },
  durationText: {
    color: '#FFF',
    fontSize: 10,
    fontWeight: '700',
  },
  details: {
    flex: 1,
    marginLeft: 12,
    justifyContent: 'center',
  },
  title: {
    color: KidColors.textLight,
    fontSize: 13,
    fontWeight: '700',
    lineHeight: 17,
    marginBottom: 4,
  },
  channel: {
    color: KidColors.textMuted,
    fontSize: 11,
  },
});

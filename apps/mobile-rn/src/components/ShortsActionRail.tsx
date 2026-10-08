import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { KidColors } from '../theme/colors';

interface Props {
  isFavorite: boolean;
  isMuted: boolean;
  onToggleFavorite: () => void;
  onToggleMute: () => void;
  onLockTouch: () => void;
  onClose: () => void;
}

export const ShortsActionRail: React.FC<Props> = ({
  isFavorite,
  isMuted,
  onToggleFavorite,
  onToggleMute,
  onLockTouch,
  onClose,
}) => {
  return (
    <View style={styles.container}>
      {/* Favorite Heart */}
      <TouchableOpacity
        activeOpacity={0.8}
        onPress={onToggleFavorite}
        style={styles.actionItem}
      >
        <View style={styles.iconCircle}>
          <Text style={{ fontSize: 24 }}>{isFavorite ? '❤️' : '🤍'}</Text>
        </View>
        <Text style={styles.actionLabel}>Like</Text>
      </TouchableOpacity>

      {/* Sound Mute/Unmute */}
      <TouchableOpacity
        activeOpacity={0.8}
        onPress={onToggleMute}
        style={styles.actionItem}
      >
        <View style={styles.iconCircle}>
          <Text style={{ fontSize: 22 }}>{isMuted ? '🔇' : '🔊'}</Text>
        </View>
        <Text style={styles.actionLabel}>{isMuted ? 'Unmute' : 'Sound'}</Text>
      </TouchableOpacity>

      {/* Toddler Touch Lock */}
      <TouchableOpacity
        activeOpacity={0.8}
        onPress={onLockTouch}
        style={styles.actionItem}
      >
        <View style={styles.iconCircle}>
          <Text style={{ fontSize: 22 }}>🔒</Text>
        </View>
        <Text style={styles.actionLabel}>Lock</Text>
      </TouchableOpacity>

      {/* Close Shorts */}
      <TouchableOpacity
        activeOpacity={0.8}
        onPress={onClose}
        style={styles.actionItem}
      >
        <View style={[styles.iconCircle, styles.closeCircle]}>
          <Text style={{ fontSize: 18, color: '#FFF', fontWeight: '800' }}>✕</Text>
        </View>
        <Text style={styles.actionLabel}>Exit</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    right: 16,
    bottom: 80,
    alignItems: 'center',
    gap: 18,
    zIndex: 50,
  },
  actionItem: {
    alignItems: 'center',
  },
  iconCircle: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: 'rgba(21, 29, 51, 0.75)',
    borderWidth: 1.2,
    borderColor: 'rgba(255, 255, 255, 0.25)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 4,
  },
  closeCircle: {
    backgroundColor: 'rgba(239, 68, 68, 0.75)',
    borderColor: 'rgba(255, 255, 255, 0.4)',
  },
  actionLabel: {
    color: KidColors.textLight,
    fontSize: 11,
    fontWeight: '700',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 3,
  },
});

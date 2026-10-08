import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
  BackHandler,
} from 'react-native';
import * as Haptics from 'expo-haptics';
import { KidColors } from '../theme/colors';

interface Props {
  isLocked: boolean;
  onUnlock: () => void;
}

export const TouchLockOverlay: React.FC<Props> = ({ isLocked, onUnlock }) => {
  const [isPressing, setIsPressing] = useState(false);
  const progressAnim = useRef(new Animated.Value(0)).current;
  const holdTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    // Intercept system back button while locked
    if (isLocked) {
      const backHandler = BackHandler.addEventListener(
        'hardwareBackPress',
        () => true // Block back button
      );
      return () => backHandler.remove();
    }
    return undefined;
  }, [isLocked]);

  if (!isLocked) return null;

  const handlePressIn = () => {
    setIsPressing(true);
    Animated.timing(progressAnim, {
      toValue: 1,
      duration: 3000,
      useNativeDriver: false,
    }).start();

    holdTimerRef.current = setTimeout(async () => {
      try {
        await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
      } catch (_) {}
      setIsPressing(false);
      progressAnim.setValue(0);
      onUnlock();
    }, 3000);
  };

  const handlePressOut = () => {
    if (holdTimerRef.current) {
      clearTimeout(holdTimerRef.current);
      holdTimerRef.current = null;
    }
    setIsPressing(false);
    Animated.timing(progressAnim, {
      toValue: 0,
      duration: 200,
      useNativeDriver: false,
    }).start();
  };

  const progressWidth = progressAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ['0%', '100%'],
  });

  return (
    <View style={styles.overlay} pointerEvents="auto">
      {/* Semi-transparent protective cover */}
      <View style={styles.blocker} />

      {/* Floating 3-second hold button */}
      <View style={styles.unlockCard}>
        <Text style={styles.lockIcon}>🔒</Text>
        <Text style={styles.title}>Toddler Lock is Active</Text>
        <Text style={styles.subtitle}>Hold button for 3 seconds to unlock</Text>

        <TouchableOpacity
          activeOpacity={0.9}
          onPressIn={handlePressIn}
          onPressOut={handlePressOut}
          style={styles.holdButton}
        >
          {/* Animated fill indicator */}
          <Animated.View
            style={[
              styles.holdProgressFill,
              { width: progressWidth },
            ]}
          />
          <Text style={styles.holdButtonText}>
            {isPressing ? 'Keep Holding...' : 'Hold 3s to Unlock'}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFill,
    zIndex: 9999,
    justifyContent: 'center',
    alignItems: 'center',
  },
  blocker: {
    ...StyleSheet.absoluteFill,
    backgroundColor: 'rgba(11, 15, 25, 0.45)',
  },
  unlockCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 24,
    padding: 24,
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: KidColors.borderDark,
    width: 280,
    shadowColor: '#000',
    shadowOpacity: 0.5,
    shadowRadius: 16,
    elevation: 10,
  },
  lockIcon: {
    fontSize: 40,
    marginBottom: 8,
  },
  title: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 4,
  },
  subtitle: {
    color: KidColors.textMuted,
    fontSize: 12,
    textAlign: 'center',
    marginBottom: 18,
  },
  holdButton: {
    width: '100%',
    height: 48,
    borderRadius: 24,
    backgroundColor: KidColors.cardElevated,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1.2,
    borderColor: KidColors.primary,
    position: 'relative',
  },
  holdProgressFill: {
    position: 'absolute',
    left: 0,
    top: 0,
    bottom: 0,
    backgroundColor: KidColors.primary,
  },
  holdButtonText: {
    color: KidColors.textLight,
    fontWeight: '800',
    fontSize: 14,
    zIndex: 1,
  },
});

import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import * as ScreenOrientation from 'expo-screen-orientation';
import { KidColors } from '../theme/colors';
import { useAppStore } from '../store/useAppStore';

export const OrientationModeSwitch: React.FC = () => {
  const { orientationMode, setOrientationMode } = useAppStore();

  const handleModeChange = async (mode: 'auto' | 'portrait' | 'landscape') => {
    setOrientationMode(mode);
    try {
      if (mode === 'portrait') {
        await ScreenOrientation.lockAsync(
          ScreenOrientation.OrientationLock.PORTRAIT_UP
        );
      } else if (mode === 'landscape') {
        await ScreenOrientation.lockAsync(
          ScreenOrientation.OrientationLock.LANDSCAPE
        );
      } else {
        await ScreenOrientation.unlockAsync();
      }
    } catch (_) {}
  };

  return (
    <View style={styles.container}>
      <TouchableOpacity
        onPress={() => handleModeChange('auto')}
        style={[
          styles.button,
          orientationMode === 'auto' && styles.buttonActive,
        ]}
      >
        <Text
          style={[
            styles.buttonText,
            orientationMode === 'auto' && styles.buttonTextActive,
          ]}
        >
          🔄 Auto
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        onPress={() => handleModeChange('portrait')}
        style={[
          styles.button,
          orientationMode === 'portrait' && styles.buttonActive,
        ]}
      >
        <Text
          style={[
            styles.buttonText,
            orientationMode === 'portrait' && styles.buttonTextActive,
          ]}
        >
          📱 Portrait
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        onPress={() => handleModeChange('landscape')}
        style={[
          styles.button,
          orientationMode === 'landscape' && styles.buttonActive,
        ]}
      >
        <Text
          style={[
            styles.buttonText,
            orientationMode === 'landscape' && styles.buttonTextActive,
          ]}
        >
          📺 Landscape
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    backgroundColor: KidColors.cardElevated,
    borderRadius: 20,
    padding: 3,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  button: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  buttonActive: {
    backgroundColor: KidColors.sky,
  },
  buttonText: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '700',
  },
  buttonTextActive: {
    color: KidColors.bgDark,
  },
});

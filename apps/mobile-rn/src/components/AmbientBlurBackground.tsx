import React from 'react';
import { View, StyleSheet } from 'react-native';
import { KidColors } from '../theme/colors';

interface Props {
  children?: React.ReactNode;
}

export const AmbientBlurBackground: React.FC<Props> = ({ children }) => {
  return (
    <View style={styles.container}>
      {/* Decorative atmospheric cosmic ambient circles */}
      <View style={styles.ambientTopLeft} />
      <View style={styles.ambientBottomRight} />
      {children}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: KidColors.bgDark,
    position: 'relative',
    overflow: 'hidden',
  },
  ambientTopLeft: {
    position: 'absolute',
    top: -80,
    left: -80,
    width: 260,
    height: 260,
    borderRadius: 130,
    backgroundColor: 'rgba(56, 189, 248, 0.08)',
  },
  ambientBottomRight: {
    position: 'absolute',
    bottom: -100,
    right: -100,
    width: 320,
    height: 320,
    borderRadius: 160,
    backgroundColor: 'rgba(255, 94, 98, 0.06)',
  },
});

import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { ChildProfile, getProfileEmoji } from '../types/profile';
import { KidColors } from '../theme/colors';

interface Props {
  profile?: ChildProfile | null;
  size?: number;
  showName?: boolean;
  isSelected?: boolean;
  onPress?: () => void;
}

export const ChildAvatar: React.FC<Props> = ({
  profile,
  size = 44,
  showName = false,
  isSelected = false,
  onPress,
}) => {
  const emoji = profile ? getProfileEmoji(profile.avatarIcon) : '🐻';
  const name = profile ? profile.name : 'Kids';

  const avatarContent = (
    <View
      style={[
        styles.avatarContainer,
        {
          width: size,
          height: size,
          borderRadius: size / 2,
          borderColor: isSelected ? KidColors.sky : KidColors.borderDark,
          borderWidth: isSelected ? 2.5 : 1.5,
        },
      ]}
    >
      <Text style={{ fontSize: size * 0.52 }}>{emoji}</Text>
    </View>
  );

  if (onPress) {
    return (
      <TouchableOpacity
        activeOpacity={0.8}
        onPress={onPress}
        style={styles.wrapper}
      >
        {avatarContent}
        {showName && (
          <Text
            numberOfLines={1}
            style={[
              styles.nameText,
              isSelected ? styles.nameTextSelected : styles.nameTextNormal,
            ]}
          >
            {name}
          </Text>
        )}
      </TouchableOpacity>
    );
  }

  return (
    <View style={styles.wrapper}>
      {avatarContent}
      {showName && (
        <Text numberOfLines={1} style={styles.nameText}>
          {name}
        </Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  wrapper: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarContainer: {
    backgroundColor: KidColors.cardElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  nameText: {
    marginTop: 6,
    color: KidColors.textLight,
    fontSize: 13,
    fontWeight: '700',
  },
  nameTextSelected: {
    color: KidColors.sky,
  },
  nameTextNormal: {
    color: KidColors.textMuted,
  },
});

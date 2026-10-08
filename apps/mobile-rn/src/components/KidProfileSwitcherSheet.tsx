import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  ScrollView,
} from 'react-native';
import { useAppStore } from '../store/useAppStore';
import { ChildAvatar } from './ChildAvatar';
import { KidColors } from '../theme/colors';

interface Props {
  visible: boolean;
  onClose: () => void;
  onOpenParentGate: () => void;
}

export const KidProfileSwitcherSheet: React.FC<Props> = ({
  visible,
  onClose,
  onOpenParentGate,
}) => {
  const { profiles, activeProfile, switchProfile } = useAppStore();

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      <TouchableOpacity
        activeOpacity={1}
        onPress={onClose}
        style={styles.backdrop}
      >
        <TouchableOpacity
          activeOpacity={1}
          style={styles.sheet}
          onPress={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <View style={styles.header}>
            <Text style={styles.title}>Who's Watching?</Text>
            <TouchableOpacity onPress={onClose} style={styles.closeBtn}>
              <Text style={styles.closeText}>✕</Text>
            </TouchableOpacity>
          </View>

          {/* Profiles Grid / List */}
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.profilesList}
          >
            {profiles.map((profile) => {
              const isSelected = activeProfile?.id === profile.id;
              return (
                <View key={profile.id} style={styles.profileItem}>
                  <ChildAvatar
                    profile={profile}
                    size={72}
                    showName
                    isSelected={isSelected}
                    onPress={() => {
                      switchProfile(profile);
                      onClose();
                    }}
                  />
                </View>
              );
            })}
          </ScrollView>

          {/* Parent Zone Access */}
          <View style={styles.parentZoneWrapper}>
            <TouchableOpacity
              activeOpacity={0.8}
              onPress={() => {
                onClose();
                onOpenParentGate();
              }}
              style={styles.parentGateBtn}
            >
              <Text style={{ fontSize: 18, marginRight: 8 }}>🛡️</Text>
              <Text style={styles.parentGateText}>Parent Dashboard</Text>
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      </TouchableOpacity>
    </Modal>
  );
};

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.65)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: KidColors.cardDark,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    paddingTop: 20,
    paddingBottom: 36,
    paddingHorizontal: 20,
    borderTopWidth: 1.5,
    borderColor: KidColors.borderDark,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  title: {
    color: KidColors.textLight,
    fontSize: 20,
    fontWeight: '800',
  },
  closeBtn: {
    padding: 6,
  },
  closeText: {
    color: KidColors.textMuted,
    fontSize: 18,
    fontWeight: '700',
  },
  profilesList: {
    paddingVertical: 12,
    gap: 20,
    alignItems: 'center',
  },
  profileItem: {
    alignItems: 'center',
    minWidth: 80,
  },
  parentZoneWrapper: {
    marginTop: 24,
    borderTopWidth: 1,
    borderColor: KidColors.borderDark,
    paddingTop: 16,
    alignItems: 'center',
  },
  parentGateBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: KidColors.cardElevated,
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  parentGateText: {
    color: KidColors.textLight,
    fontWeight: '700',
    fontSize: 14,
  },
});

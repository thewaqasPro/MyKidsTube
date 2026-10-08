import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
  Modal,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { KidColors } from '../theme/colors';
import { ChildAvatar } from '../components/ChildAvatar';
import { formatBytes } from '../utils/urlHelpers';

type Props = NativeStackScreenProps<RootStackParamList, 'ParentDashboard'>;

export const ParentDashboardScreen: React.FC<Props> = ({ navigation }) => {
  const {
    deviceName,
    isDevicePaired,
    activeProfile,
    videos,
    cachedBytes,
    isSyncingCatalog,
    syncCatalog,
    unpairDevice,
    pendingPrune,
    confirmPrune,
    cancelPrune,
  } = useAppStore();

  const handleUnpair = () => {
    Alert.alert(
      'Unpair Tablet',
      'Are you sure you want to disconnect this device from your Parent Portal? You will need a new 6-digit code to pair again.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Unpair',
          style: 'destructive',
          onPress: async () => {
            await unpairDevice();
            navigation.replace('DevicePairing');
          },
        },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Top Header */}
        <View style={styles.headerRow}>
          <View>
            <Text style={styles.title}>Parent Dashboard</Text>
            <Text style={styles.subtitle}>Protected grown-ups control center</Text>
          </View>
          <TouchableOpacity
            onPress={() => navigation.navigate('KidHome')}
            style={styles.returnKidButton}
          >
            <Text style={styles.returnKidText}>👶 Exit to Kid Mode</Text>
          </TouchableOpacity>
        </View>

        {/* Device Status Card */}
        <View style={styles.statusCard}>
          <View style={styles.statusLeft}>
            <Text style={styles.deviceName}>{deviceName}</Text>
            <View style={styles.connectedRow}>
              <View
                style={[
                  styles.statusDot,
                  { backgroundColor: isDevicePaired ? KidColors.mint : KidColors.primary },
                ]}
              />
              <Text style={styles.statusLabel}>
                {isDevicePaired ? 'Paired & Synchronized' : 'Not Paired'}
              </Text>
            </View>
            <Text style={styles.statsSummary}>
              {videos.length} videos available • {formatBytes(cachedBytes)} cached
            </Text>
          </View>

          <View style={styles.statusRight}>
            <TouchableOpacity
              disabled={isSyncingCatalog}
              onPress={syncCatalog}
              style={styles.syncButton}
            >
              {isSyncingCatalog ? (
                <ActivityIndicator size="small" color="#FFF" />
              ) : (
                <Text style={styles.syncButtonText}>🔄 Sync</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>

        {/* Active Child Profile Card */}
        {activeProfile && (
          <View style={styles.profileCard}>
            <ChildAvatar profile={activeProfile} size={50} />
            <View style={styles.profileTextWrapper}>
              <Text style={styles.profileTitle}>Active Child Profile</Text>
              <Text style={styles.profileName}>{activeProfile.name}</Text>
            </View>
          </View>
        )}

        {/* Dashboard Menu Tiles */}
        <Text style={styles.sectionTitle}>Controls & Management</Text>
        <View style={styles.grid}>
          {/* 1. Media Library */}
          <TouchableOpacity
            onPress={() => navigation.navigate('ParentMediaLibrary')}
            style={styles.menuTile}
          >
            <Text style={styles.tileIcon}>🎬</Text>
            <Text style={styles.tileTitle}>Media Library</Text>
            <Text style={styles.tileDesc}>
              Add new YouTube links, curate videos, and manage catalog
            </Text>
          </TouchableOpacity>

          {/* 2. Storage & Downloads */}
          <TouchableOpacity
            onPress={() => navigation.navigate('ParentStorage')}
            style={styles.menuTile}
          >
            <Text style={styles.tileIcon}>💾</Text>
            <Text style={styles.tileTitle}>Offline Storage</Text>
            <Text style={styles.tileDesc}>
              Download All for road trips, view storage gauge, and clear cache
            </Text>
          </TouchableOpacity>

          {/* 3. Server Configuration */}
          <TouchableOpacity
            onPress={() => navigation.navigate('ParentServer')}
            style={styles.menuTile}
          >
            <Text style={styles.tileIcon}>🌐</Text>
            <Text style={styles.tileTitle}>Server & Network</Text>
            <Text style={styles.tileDesc}>
              Manage edge endpoint, check latency, and test health
            </Text>
          </TouchableOpacity>

          {/* 4. Security & PIN */}
          <TouchableOpacity
            onPress={() => navigation.navigate('ParentSecurity')}
            style={styles.menuTile}
          >
            <Text style={styles.tileIcon}>🛡️</Text>
            <Text style={styles.tileTitle}>Security & PIN</Text>
            <Text style={styles.tileDesc}>
              Update salted 4-digit PIN protecting parental controls
            </Text>
          </TouchableOpacity>

          {/* 5. Watch Time & Analytics */}
          <TouchableOpacity
            onPress={() => navigation.navigate('ParentAnalytics')}
            style={styles.menuTile}
          >
            <Text style={styles.tileIcon}>📊</Text>
            <Text style={styles.tileTitle}>Watch Analytics</Text>
            <Text style={styles.tileDesc}>
              Track screen time, top categories, and sync metrics
            </Text>
          </TouchableOpacity>
        </View>

        {/* Unpair Button */}
        <TouchableOpacity
          onPress={handleUnpair}
          style={styles.unpairButton}
        >
          <Text style={styles.unpairText}>Disconnect / Unpair Tablet</Text>
        </TouchableOpacity>
      </ScrollView>

      {/* Safety Cap Confirmation Modal */}
      <Modal
        visible={!!pendingPrune}
        transparent
        animationType="fade"
      >
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.warningIcon}>⚠️</Text>
            <Text style={styles.modalHeading}>Prune Safety Cap Triggered</Text>
            <Text style={styles.modalBody}>
              The server catalog removed {pendingPrune?.toDeleteCount} out of {pendingPrune?.totalCount} local videos (over 50%).
              {'\n\n'}
              To prevent accidental loss of downloaded offline media, destructive deletion requires your explicit confirmation.
            </Text>
            <View style={styles.modalBtnRow}>
              <TouchableOpacity
                onPress={cancelPrune}
                style={[styles.modalBtn, styles.modalCancelBtn]}
              >
                <Text style={styles.modalCancelText}>Keep Local Files</Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={confirmPrune}
                style={[styles.modalBtn, styles.modalDeleteBtn]}
              >
                <Text style={styles.modalDeleteText}>Confirm Deletion</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: KidColors.bgDark,
  },
  scrollContent: {
    padding: 24,
    paddingBottom: 48,
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  title: {
    color: KidColors.textLight,
    fontSize: 24,
    fontWeight: '800',
  },
  subtitle: {
    color: KidColors.textMuted,
    fontSize: 13,
    marginTop: 2,
  },
  returnKidButton: {
    backgroundColor: KidColors.cardElevated,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: KidColors.sky,
  },
  returnKidText: {
    color: KidColors.sky,
    fontWeight: '800',
    fontSize: 13,
  },
  statusCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 22,
    padding: 20,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  statusLeft: {
    flex: 1,
  },
  deviceName: {
    color: KidColors.textLight,
    fontSize: 18,
    fontWeight: '800',
    marginBottom: 4,
  },
  connectedRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 6,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  statusLabel: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '600',
  },
  statsSummary: {
    color: KidColors.textTertiary,
    fontSize: 12,
  },
  statusRight: {
    marginLeft: 12,
  },
  syncButton: {
    backgroundColor: KidColors.sky,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 14,
  },
  syncButtonText: {
    color: KidColors.bgDark,
    fontWeight: '800',
    fontSize: 13,
  },
  profileCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 20,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    marginBottom: 24,
    gap: 14,
  },
  profileTextWrapper: {
    flex: 1,
  },
  profileTitle: {
    color: KidColors.textTertiary,
    fontSize: 11,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  profileName: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
  },
  sectionTitle: {
    color: KidColors.textLight,
    fontSize: 17,
    fontWeight: '800',
    marginBottom: 14,
  },
  grid: {
    gap: 12,
    marginBottom: 28,
  },
  menuTile: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 20,
    padding: 18,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
  },
  tileIcon: {
    fontSize: 28,
    marginBottom: 10,
  },
  tileTitle: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 4,
  },
  tileDesc: {
    color: KidColors.textMuted,
    fontSize: 13,
    lineHeight: 18,
  },
  unpairButton: {
    backgroundColor: 'rgba(239, 68, 68, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(239, 68, 68, 0.4)',
    paddingVertical: 14,
    borderRadius: 16,
    alignItems: 'center',
  },
  unpairText: {
    color: '#EF4444',
    fontSize: 14,
    fontWeight: '800',
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.8)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  modalCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 24,
    padding: 24,
    width: '100%',
    maxWidth: 420,
    borderWidth: 1.5,
    borderColor: KidColors.primary,
    alignItems: 'center',
  },
  warningIcon: {
    fontSize: 44,
    marginBottom: 10,
  },
  modalHeading: {
    color: KidColors.textLight,
    fontSize: 20,
    fontWeight: '800',
    marginBottom: 8,
    textAlign: 'center',
  },
  modalBody: {
    color: KidColors.textMuted,
    fontSize: 13,
    textAlign: 'center',
    lineHeight: 19,
    marginBottom: 20,
  },
  modalBtnRow: {
    flexDirection: 'row',
    gap: 12,
    width: '100%',
  },
  modalBtn: {
    flex: 1,
    height: 46,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalCancelBtn: {
    backgroundColor: KidColors.cardElevated,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  modalCancelText: {
    color: KidColors.textLight,
    fontWeight: '700',
  },
  modalDeleteBtn: {
    backgroundColor: KidColors.primary,
  },
  modalDeleteText: {
    color: '#FFF',
    fontWeight: '800',
  },
});

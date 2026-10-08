import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { WatchAnalytics } from '../types/profile';
import { KidColors } from '../theme/colors';

type Props = NativeStackScreenProps<RootStackParamList, 'ParentAnalytics'>;

export const ParentAnalyticsScreen: React.FC<Props> = ({ navigation }) => {
  const { getWatchAnalytics, syncWatchMetrics, activeProfile } = useAppStore();

  const [analytics, setAnalytics] = useState<WatchAnalytics | null>(null);
  const [isSyncing, setIsSyncing] = useState(false);

  useEffect(() => {
    loadAnalytics();
  }, [activeProfile]);

  const loadAnalytics = async () => {
    const data = await getWatchAnalytics();
    setAnalytics(data);
  };

  const handleSync = async () => {
    setIsSyncing(true);
    await syncWatchMetrics();
    await loadAnalytics();
    setIsSyncing(false);
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          style={styles.backButton}
        >
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Watch Analytics</Text>
        <TouchableOpacity
          disabled={isSyncing}
          onPress={handleSync}
          style={styles.syncBtn}
        >
          {isSyncing ? (
            <ActivityIndicator size="small" color={KidColors.sky} />
          ) : (
            <Text style={styles.syncText}>☁️ Sync</Text>
          )}
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Profile Tag */}
        <View style={styles.profileBadge}>
          <Text style={styles.profileBadgeText}>
            Child Profile: {activeProfile ? activeProfile.name : 'All Profiles'}
          </Text>
        </View>

        {/* 4 Metrics Grid */}
        <View style={styles.grid}>
          {/* Total Time */}
          <View style={styles.statCard}>
            <Text style={styles.statIcon}>⏱️</Text>
            <Text style={styles.statVal}>
              {analytics?.totalWatchedFormatted || '0 mins'}
            </Text>
            <Text style={styles.statLabel}>Total Screen Time</Text>
          </View>

          {/* Videos Watched */}
          <View style={styles.statCard}>
            <Text style={styles.statIcon}>🎬</Text>
            <Text style={styles.statVal}>{analytics?.totalViews || 0}</Text>
            <Text style={styles.statLabel}>Videos Watched</Text>
          </View>

          {/* Completion Rate */}
          <View style={styles.statCard}>
            <Text style={styles.statIcon}>📈</Text>
            <Text style={styles.statVal}>{analytics?.completionRate || 0}%</Text>
            <Text style={styles.statLabel}>Avg Completion Rate</Text>
          </View>

          {/* Top Category */}
          <View style={styles.statCard}>
            <Text style={styles.statIcon}>🌟</Text>
            <Text style={styles.statVal} numberOfLines={1}>
              {analytics?.mostWatchedCategory || 'None'}
            </Text>
            <Text style={styles.statLabel}>Top Category</Text>
          </View>
        </View>

        {/* Recent Watch History */}
        <Text style={styles.sectionTitle}>Recently Watched Videos</Text>
        {(!analytics?.recentTitles || analytics.recentTitles.length === 0) ? (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyText}>
              No watch history recorded yet. As your child watches videos, sessions will appear here.
            </Text>
          </View>
        ) : (
          <View style={styles.historyList}>
            {analytics.recentTitles.map((title, idx) => (
              <View key={idx} style={styles.historyItem}>
                <Text style={styles.historyNumber}>{idx + 1}</Text>
                <Text numberOfLines={1} style={styles.historyTitle}>
                  {title}
                </Text>
              </View>
            ))}
          </View>
        )}

        {/* Cloud Sync Description */}
        <View style={styles.syncCard}>
          <Text style={styles.syncCardTitle}>Cloud Portal Sync</Text>
          <Text style={styles.syncCardSub}>
            Watch events are stored locally in SQLite and synced anonymously to the Parent Portal API to help you understand your child's viewing interests.
          </Text>
          <TouchableOpacity
            disabled={isSyncing}
            onPress={handleSync}
            style={styles.syncActionBtn}
          >
            <Text style={styles.syncActionText}>
              {isSyncing ? 'Synchronizing...' : 'Upload Watch Events Now'}
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: KidColors.bgDark,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderColor: KidColors.borderDark,
  },
  backButton: {
    padding: 6,
  },
  backText: {
    color: KidColors.sky,
    fontWeight: '700',
    fontSize: 15,
  },
  headerTitle: {
    color: KidColors.textLight,
    fontSize: 18,
    fontWeight: '800',
  },
  syncBtn: {
    padding: 6,
  },
  syncText: {
    color: KidColors.sky,
    fontWeight: '700',
    fontSize: 14,
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 40,
  },
  profileBadge: {
    alignSelf: 'flex-start',
    backgroundColor: KidColors.cardElevated,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    marginBottom: 16,
  },
  profileBadgeText: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '700',
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    marginBottom: 24,
  },
  statCard: {
    flexBasis: '48%',
    backgroundColor: KidColors.cardDark,
    borderRadius: 20,
    padding: 18,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
  },
  statIcon: {
    fontSize: 26,
    marginBottom: 8,
  },
  statVal: {
    color: KidColors.textLight,
    fontSize: 20,
    fontWeight: '800',
    marginBottom: 4,
  },
  statLabel: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '600',
  },
  sectionTitle: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 12,
  },
  emptyCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 18,
    padding: 20,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    alignItems: 'center',
    marginBottom: 24,
  },
  emptyText: {
    color: KidColors.textMuted,
    fontSize: 13,
    textAlign: 'center',
    lineHeight: 18,
  },
  historyList: {
    gap: 8,
    marginBottom: 24,
  },
  historyItem: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 14,
    padding: 12,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    gap: 12,
  },
  historyNumber: {
    color: KidColors.sky,
    fontWeight: '800',
    fontSize: 14,
    width: 20,
  },
  historyTitle: {
    flex: 1,
    color: KidColors.textLight,
    fontSize: 13,
    fontWeight: '600',
  },
  syncCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 20,
    padding: 20,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
  },
  syncCardTitle: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 6,
  },
  syncCardSub: {
    color: KidColors.textMuted,
    fontSize: 12,
    lineHeight: 17,
    marginBottom: 16,
  },
  syncActionBtn: {
    backgroundColor: KidColors.cardElevated,
    borderWidth: 1,
    borderColor: KidColors.sky,
    borderRadius: 14,
    paddingVertical: 12,
    alignItems: 'center',
  },
  syncActionText: {
    color: KidColors.sky,
    fontWeight: '800',
    fontSize: 14,
  },
});

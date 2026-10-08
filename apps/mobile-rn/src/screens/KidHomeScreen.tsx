import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  Image,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { KidColors } from '../theme/colors';
import { ChildAvatar } from '../components/ChildAvatar';
import { VideoCard } from '../components/VideoCard';
import { KidProfileSwitcherSheet } from '../components/KidProfileSwitcherSheet';
import { ParentGateModal } from '../components/ParentGateModal';
import { isVideoShort, getThumbnailUrl } from '../utils/urlHelpers';
import { VideoItem } from '../types/video';

type Props = NativeStackScreenProps<RootStackParamList, 'KidHome'>;

export const KidHomeScreen: React.FC<Props> = ({ navigation }) => {
  const {
    videos,
    categories,
    activeCategoryId,
    setActiveCategory,
    activeProfile,
    vpsUrl,
    syncCatalog,
    isSyncingCatalog,
  } = useAppStore();

  const [profileSheetVisible, setProfileSheetVisible] = useState(false);
  const [parentGateVisible, setParentGateVisible] = useState(false);

  // Separate shorts from long-form videos
  const shortsList = videos.filter((v) => isVideoShort(v));

  // Filter long-form videos by active category
  const displayVideos = videos.filter((v) => {
    if (activeCategoryId !== 'all' && v.categoryId !== activeCategoryId) {
      return false;
    }
    return true;
  });

  const handleParentGateSuccess = (isForcePinChangeRequired: boolean) => {
    setParentGateVisible(false);
    if (isForcePinChangeRequired) {
      navigation.navigate('ParentSecurity', { isForceChange: true });
    } else {
      navigation.navigate('ParentDashboard');
    }
  };

  return (
    <View style={styles.container}>
      {/* Top App Bar */}
      <View style={styles.appBar}>
        {/* Child Profile Trigger */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={() => setProfileSheetVisible(true)}
          style={styles.profileTrigger}
        >
          <ChildAvatar profile={activeProfile} size={40} />
          <View style={styles.profileMeta}>
            <Text numberOfLines={1} style={styles.profileName}>
              {activeProfile ? activeProfile.name : 'Kids'}
            </Text>
            <Text style={styles.switchText}>Switch ▾</Text>
          </View>
        </TouchableOpacity>

        {/* Brand Title */}
        <View style={styles.brandTitleWrapper}>
          <Text style={styles.brandEmoji}>📺</Text>
          <Text style={styles.brandTitle}>KidsTube</Text>
        </View>

        {/* Parent Gate Button */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={() => setParentGateVisible(true)}
          style={styles.parentGateBtn}
        >
          <Text style={{ fontSize: 20 }}>🛡️</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={displayVideos}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={isSyncingCatalog}
            onRefresh={syncCatalog}
            tintColor={KidColors.primary}
            colors={[KidColors.primary, KidColors.sky]}
          />
        }
        ListHeaderComponent={
          <View>
            {/* Category Filter Chips */}
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.categoryChips}
            >
              {/* All Chip */}
              <TouchableOpacity
                onPress={() => setActiveCategory('all')}
                style={[
                  styles.chip,
                  activeCategoryId === 'all'
                    ? styles.chipSelected
                    : styles.chipUnselected,
                ]}
              >
                <Text
                  style={[
                    styles.chipText,
                    activeCategoryId === 'all'
                      ? styles.chipTextSelected
                      : styles.chipTextUnselected,
                  ]}
                >
                  🌈 All
                </Text>
              </TouchableOpacity>

              {/* Dynamic Categories */}
              {categories.map((cat) => {
                const isSelected = activeCategoryId === cat.id;
                return (
                  <TouchableOpacity
                    key={cat.id}
                    onPress={() => setActiveCategory(cat.id)}
                    style={[
                      styles.chip,
                      isSelected ? styles.chipSelected : styles.chipUnselected,
                    ]}
                  >
                    <Text
                      style={[
                        styles.chipText,
                        isSelected
                          ? styles.chipTextSelected
                          : styles.chipTextUnselected,
                      ]}
                    >
                      {cat.name}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>

            {/* YouTube Shorts Shelf (if shorts exist) */}
            {shortsList.length > 0 && (
              <View style={styles.shortsShelf}>
                <View style={styles.shortsHeaderRow}>
                  <Text style={styles.shortsShelfTitle}>⚡ Quick Shorts</Text>
                  <TouchableOpacity
                    onPress={() => navigation.navigate('KidShortsFeed')}
                  >
                    <Text style={styles.seeAllShortsText}>Watch All →</Text>
                  </TouchableOpacity>
                </View>

                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  contentContainerStyle={styles.shortsScrollContent}
                >
                  {shortsList.map((short) => (
                    <TouchableOpacity
                      key={short.id}
                      activeOpacity={0.85}
                      onPress={() =>
                        navigation.navigate('KidShortsFeed', {
                          initialVideoId: short.id,
                        })
                      }
                      style={styles.shortCard}
                    >
                      <Image
                        source={{ uri: getThumbnailUrl(short, vpsUrl) }}
                        style={styles.shortThumb}
                        resizeMode="cover"
                      />
                      <View style={styles.shortBadge}>
                        <Text style={styles.shortBadgeText}>⚡ Short</Text>
                      </View>
                      <View style={styles.shortOverlay}>
                        <Text numberOfLines={2} style={styles.shortTitle}>
                          {short.title}
                        </Text>
                      </View>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>
            )}

            <Text style={styles.sectionHeader}>Watch Safe Videos</Text>
          </View>
        }
        renderItem={({ item }) => (
          <VideoCard
            video={item}
            vpsUrl={vpsUrl}
            onPress={() =>
              navigation.navigate('KidPlayer', { videoId: item.id })
            }
          />
        )}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>🎈</Text>
            <Text style={styles.emptyTitle}>No Videos in this Category</Text>
            <Text style={styles.emptySub}>
              Ask a grown-up to add fun videos to your catalog from the Parent Dashboard!
            </Text>
          </View>
        }
      />

      {/* Profile Switcher Bottom Sheet */}
      <KidProfileSwitcherSheet
        visible={profileSheetVisible}
        onClose={() => setProfileSheetVisible(false)}
        onOpenParentGate={() => setParentGateVisible(true)}
      />

      {/* Parent Gate Challenge Modal */}
      <ParentGateModal
        visible={parentGateVisible}
        onClose={() => setParentGateVisible(false)}
        onSuccess={handleParentGateSuccess}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: KidColors.bgDark,
  },
  appBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderColor: KidColors.borderDark,
    backgroundColor: KidColors.bgDark,
  },
  profileTrigger: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  profileMeta: {
    justifyContent: 'center',
  },
  profileName: {
    color: KidColors.textLight,
    fontSize: 14,
    fontWeight: '800',
    maxWidth: 90,
  },
  switchText: {
    color: KidColors.sky,
    fontSize: 11,
    fontWeight: '700',
  },
  brandTitleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  brandEmoji: {
    fontSize: 22,
  },
  brandTitle: {
    color: KidColors.textLight,
    fontSize: 19,
    fontWeight: '900',
    letterSpacing: -0.4,
  },
  parentGateBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: KidColors.cardElevated,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  listContent: {
    padding: 16,
  },
  categoryChips: {
    gap: 10,
    paddingBottom: 16,
  },
  chip: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 18,
    borderWidth: 1,
  },
  chipSelected: {
    backgroundColor: KidColors.chipSelectedBg,
    borderColor: KidColors.chipSelectedBg,
  },
  chipUnselected: {
    backgroundColor: KidColors.chipUnselectedBg,
    borderColor: KidColors.borderDark,
  },
  chipText: {
    fontSize: 13,
    fontWeight: '800',
  },
  chipTextSelected: {
    color: KidColors.chipSelectedText,
  },
  chipTextUnselected: {
    color: KidColors.chipUnselectedText,
  },
  shortsShelf: {
    marginBottom: 24,
    backgroundColor: KidColors.surfaceDark,
    borderRadius: 22,
    padding: 14,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  shortsHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  shortsShelfTitle: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
  },
  seeAllShortsText: {
    color: KidColors.accent,
    fontSize: 13,
    fontWeight: '700',
  },
  shortsScrollContent: {
    gap: 12,
  },
  shortCard: {
    width: 120,
    height: 190,
    borderRadius: 16,
    overflow: 'hidden',
    position: 'relative',
    backgroundColor: KidColors.cardDark,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
  },
  shortThumb: {
    width: '100%',
    height: '100%',
  },
  shortBadge: {
    position: 'absolute',
    top: 6,
    left: 6,
    backgroundColor: 'rgba(255, 94, 98, 0.9)',
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  shortBadgeText: {
    color: '#FFF',
    fontSize: 9,
    fontWeight: '800',
  },
  shortOverlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: 8,
    backgroundColor: 'rgba(11, 15, 25, 0.85)',
  },
  shortTitle: {
    color: KidColors.textLight,
    fontSize: 11,
    fontWeight: '700',
    lineHeight: 14,
  },
  sectionHeader: {
    color: KidColors.textLight,
    fontSize: 17,
    fontWeight: '800',
    marginBottom: 14,
  },
  emptyContainer: {
    padding: 40,
    alignItems: 'center',
    backgroundColor: KidColors.cardDark,
    borderRadius: 22,
    marginTop: 10,
  },
  emptyIcon: {
    fontSize: 44,
    marginBottom: 12,
  },
  emptyTitle: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 6,
  },
  emptySub: {
    color: KidColors.textMuted,
    fontSize: 13,
    textAlign: 'center',
    lineHeight: 18,
  },
});

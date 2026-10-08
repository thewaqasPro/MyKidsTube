import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  FlatList,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { vpsApiService } from '../services/VpsApiService';
import { KidColors } from '../theme/colors';
import { VideoTile } from '../components/VideoTile';
import { VideoItem } from '../types/video';

type Props = NativeStackScreenProps<RootStackParamList, 'ParentMediaLibrary'>;

export const ParentMediaLibraryScreen: React.FC<Props> = ({ navigation }) => {
  const { vpsUrl, videos, categories, syncCatalog, isSyncingCatalog } = useAppStore();

  const [inputUrl, setInputUrl] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('cartoons');
  const [selectedQuality, setSelectedQuality] = useState('720p');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [feedbackMessage, setFeedbackMessage] = useState<{
    text: string;
    isError: boolean;
  } | null>(null);

  const handleIngest = async () => {
    const trimmed = inputUrl.trim();
    if (!trimmed) {
      setFeedbackMessage({ text: 'Please enter a valid YouTube URL.', isError: true });
      return;
    }

    setIsSubmitting(true);
    setFeedbackMessage(null);

    const success = await vpsApiService.ingestUrl(vpsUrl, trimmed, {
      categoryId: selectedCategory,
      quality: selectedQuality,
    });

    setIsSubmitting(false);

    if (success) {
      setInputUrl('');
      setFeedbackMessage({
        text: 'Video added to ingest queue! Syncing catalog...',
        isError: false,
      });
      await syncCatalog();
    } else {
      setFeedbackMessage({
        text: 'Failed to ingest video. Please check URL and server status.',
        isError: true,
      });
    }
  };

  const handleDeleteVideo = (video: VideoItem) => {
    Alert.alert(
      'Delete Video',
      `Are you sure you want to delete "${video.title}" from the kids catalog?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            await vpsApiService.deleteVideos(vpsUrl, [video.id]);
            await syncCatalog();
          },
        },
      ]
    );
  };

  const filteredVideos = videos.filter((v) =>
    v.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

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
        <Text style={styles.headerTitle}>Media Library</Text>
        <TouchableOpacity
          disabled={isSyncingCatalog}
          onPress={syncCatalog}
          style={styles.refreshButton}
        >
          {isSyncingCatalog ? (
            <ActivityIndicator size="small" color={KidColors.sky} />
          ) : (
            <Text style={styles.refreshText}>🔄</Text>
          )}
        </TouchableOpacity>
      </View>

      <FlatList
        data={filteredVideos}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        ListHeaderComponent={
          <View>
            {/* Ingest Card */}
            <View style={styles.ingestCard}>
              <Text style={styles.cardHeading}>➕ Add YouTube Video or Short</Text>
              <Text style={styles.cardSub}>
                Paste any YouTube watch or shorts URL to queue for kid-safe playback:
              </Text>

              <TextInput
                style={styles.input}
                value={inputUrl}
                onChangeText={setInputUrl}
                placeholder="https://www.youtube.com/watch?v=..."
                placeholderTextColor={KidColors.textTertiary}
                autoCapitalize="none"
                autoCorrect={false}
              />

              {/* Category Pills */}
              <Text style={styles.inputLabel}>Category</Text>
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.chipsRow}
              >
                {categories.map((c) => {
                  const isSelected = selectedCategory === c.id;
                  return (
                    <TouchableOpacity
                      key={c.id}
                      onPress={() => setSelectedCategory(c.id)}
                      style={[
                        styles.chip,
                        isSelected ? styles.chipSelected : styles.chipNormal,
                      ]}
                    >
                      <Text
                        style={[
                          styles.chipText,
                          isSelected && styles.chipTextSelected,
                        ]}
                      >
                        {c.name}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </ScrollView>

              {/* Quality selector */}
              <Text style={styles.inputLabel}>Quality</Text>
              <View style={styles.qualityRow}>
                {['720p', '1080p', '480p'].map((q) => {
                  const isSelected = selectedQuality === q;
                  return (
                    <TouchableOpacity
                      key={q}
                      onPress={() => setSelectedQuality(q)}
                      style={[
                        styles.qualityBtn,
                        isSelected && styles.qualityBtnSelected,
                      ]}
                    >
                      <Text
                        style={[
                          styles.qualityText,
                          isSelected && styles.qualityTextSelected,
                        ]}
                      >
                        {q}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>

              {feedbackMessage && (
                <Text
                  style={[
                    styles.feedbackText,
                    feedbackMessage.isError
                      ? styles.feedbackError
                      : styles.feedbackSuccess,
                  ]}
                >
                  {feedbackMessage.text}
                </Text>
              )}

              <TouchableOpacity
                disabled={isSubmitting}
                onPress={handleIngest}
                style={[
                  styles.submitButton,
                  isSubmitting && { opacity: 0.6 },
                ]}
              >
                {isSubmitting ? (
                  <ActivityIndicator size="small" color="#FFF" />
                ) : (
                  <Text style={styles.submitButtonText}>Queue Video</Text>
                )}
              </TouchableOpacity>
            </View>

            {/* Catalog Search & Count */}
            <View style={styles.searchRow}>
              <Text style={styles.catalogTitle}>
                Curated Catalog ({videos.length})
              </Text>
              <TextInput
                style={styles.searchInput}
                value={searchQuery}
                onChangeText={setSearchQuery}
                placeholder="Search catalog..."
                placeholderTextColor={KidColors.textTertiary}
              />
            </View>
          </View>
        }
        renderItem={({ item }) => (
          <View style={styles.videoItemRow}>
            <View style={{ flex: 1 }}>
              <VideoTile
                video={item}
                vpsUrl={vpsUrl}
                onPress={() =>
                  navigation.navigate('KidPlayer', { videoId: item.id })
                }
              />
            </View>
            <TouchableOpacity
              onPress={() => handleDeleteVideo(item)}
              style={styles.deleteBtn}
            >
              <Text style={styles.deleteIcon}>🗑️</Text>
            </TouchableOpacity>
          </View>
        )}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>
              {searchQuery ? 'No matching videos found.' : 'Catalog is empty.'}
            </Text>
          </View>
        }
      />
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
  refreshButton: {
    padding: 6,
  },
  refreshText: {
    fontSize: 18,
  },
  listContent: {
    padding: 20,
  },
  ingestCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 22,
    padding: 20,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
    marginBottom: 24,
  },
  cardHeading: {
    color: KidColors.textLight,
    fontSize: 17,
    fontWeight: '800',
    marginBottom: 4,
  },
  cardSub: {
    color: KidColors.textMuted,
    fontSize: 12,
    marginBottom: 16,
    lineHeight: 16,
  },
  input: {
    backgroundColor: KidColors.bgDark,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    paddingHorizontal: 14,
    height: 46,
    color: KidColors.textLight,
    fontSize: 14,
    marginBottom: 14,
  },
  inputLabel: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 8,
  },
  chipsRow: {
    gap: 8,
    marginBottom: 14,
  },
  chip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 14,
    borderWidth: 1,
  },
  chipNormal: {
    backgroundColor: KidColors.cardElevated,
    borderColor: KidColors.borderDark,
  },
  chipSelected: {
    backgroundColor: KidColors.sky,
    borderColor: KidColors.sky,
  },
  chipText: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '700',
  },
  chipTextSelected: {
    color: KidColors.bgDark,
  },
  qualityRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 16,
  },
  qualityBtn: {
    flex: 1,
    height: 38,
    borderRadius: 12,
    backgroundColor: KidColors.cardElevated,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    justifyContent: 'center',
    alignItems: 'center',
  },
  qualityBtnSelected: {
    backgroundColor: KidColors.accent,
    borderColor: KidColors.accent,
  },
  qualityText: {
    color: KidColors.textMuted,
    fontWeight: '700',
    fontSize: 13,
  },
  qualityTextSelected: {
    color: KidColors.bgDark,
  },
  feedbackText: {
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 12,
    textAlign: 'center',
  },
  feedbackError: {
    color: KidColors.primary,
  },
  feedbackSuccess: {
    color: KidColors.mint,
  },
  submitButton: {
    backgroundColor: KidColors.primary,
    height: 48,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  submitButtonText: {
    color: '#FFF',
    fontSize: 15,
    fontWeight: '800',
  },
  searchRow: {
    marginBottom: 16,
  },
  catalogTitle: {
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 8,
  },
  searchInput: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    paddingHorizontal: 12,
    height: 40,
    color: KidColors.textLight,
    fontSize: 13,
  },
  videoItemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  deleteBtn: {
    padding: 8,
    backgroundColor: 'rgba(239, 68, 68, 0.1)',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(239, 68, 68, 0.3)',
    marginBottom: 10,
  },
  deleteIcon: {
    fontSize: 16,
  },
  emptyContainer: {
    padding: 32,
    alignItems: 'center',
  },
  emptyText: {
    color: KidColors.textTertiary,
    fontSize: 14,
  },
});

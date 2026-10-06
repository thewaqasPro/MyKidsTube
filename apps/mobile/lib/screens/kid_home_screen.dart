import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_item.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/video_card.dart';
import 'kid_player_screen.dart';
import 'kid_shorts_feed_screen.dart';
import 'parent_gate_dialog.dart';
import 'profile_selector_dialog.dart';

/// Authentic YouTube / YouTube Kids Home Feed Screen
class KidHomeScreen extends StatefulWidget {
  const KidHomeScreen({super.key});

  @override
  State<KidHomeScreen> createState() => _KidHomeScreenState();
}

class _KidHomeScreenState extends State<KidHomeScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final videos = _filterVideos(provider);

        return Scaffold(
          backgroundColor: KidColors.bgDark,
          appBar: _buildYouTubeAppBar(context, provider),
          body: RefreshIndicator(
            color: KidColors.primary,
            backgroundColor: KidColors.cardDark,
            onRefresh: () => provider.syncCatalog(),
            child: Column(
              children: [
                // 1. YouTube Horizontal Filter Pills Bar
                _buildCategoryPills(provider),

                // 2. Responsive Main Video Feed / Grid
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: KidColors.primary))
                      : (videos.isEmpty
                          ? _buildEmptyState(context, provider)
                          : _buildResponsiveFeed(context, provider, videos)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TOP APP BAR (YOUTUBE MODERN)
  // ==========================================
  PreferredSizeWidget _buildYouTubeAppBar(BuildContext context, AppProvider provider) {
    if (_isSearchOpen) {
      return AppBar(
        backgroundColor: KidColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearchOpen = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'Roboto', color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search fun videos...',
            hintStyle: TextStyle(fontFamily: 'Roboto', color: KidColors.textMuted),
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, color: KidColors.textMuted),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          const SizedBox(width: 8),
        ],
      );
    }

    return AppBar(
      backgroundColor: KidColors.bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 14,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // YouTube Red Logo Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: KidColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 7),
          const Text(
            'KidsTube',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        // 1. Search Button
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 23),
          tooltip: 'Search',
          onPressed: () => setState(() => _isSearchOpen = true),
        ),

        // 2. Offline Mode Quick Indicator (if offline)
        if (provider.isOfflineOnly)
          GestureDetector(
            onTap: () => provider.toggleOfflineOnly(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: KidColors.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: KidColors.primary, width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, color: KidColors.primary, size: 12),
                  SizedBox(width: 3),
                  Text(
                    'Offline',
                    style: TextStyle(fontFamily: 'Roboto', color: KidColors.primary, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        // 3. Parent Lock Icon (Minimal)
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Parent Dashboard',
          icon: const Icon(Icons.shield_outlined, color: KidColors.textMuted, size: 21),
          onPressed: () => ParentGateDialog.show(context),
        ),

        // 4. Authentic YouTube Profile Avatar
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: GestureDetector(
            onTap: () => _showAccountModal(context, provider),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: KidColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: KidColors.borderDark, width: 1.2),
              ),
              child: Center(
                child: Text(
                  provider.activeProfile?.emojiAvatar ?? '🐻',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TOP CATEGORY FILTER PILLS (YOUTUBE STANDARD)
  // ==========================================
  Widget _buildCategoryPills(AppProvider provider) {
    final List<Map<String, String>> filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'shorts', 'label': '⚡ Shorts & Reels'},
      if (provider.favoriteVideos.isNotEmpty) {'id': 'favorites', 'label': '⭐ Favorites'},
      if (provider.downloadedVideos.isNotEmpty && !provider.isOfflineOnly) {'id': 'downloaded', 'label': '📥 Saved'},
      for (final cat in provider.categories) {'id': cat.id, 'label': cat.name},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: KidColors.bgDark,
        border: Border(bottom: BorderSide(color: KidColors.borderDark, width: 0.5)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['id'];

          return GestureDetector(
            onTap: () {
              if (filter['id'] == 'shorts') {
                // Tapping Shorts pill launches the dedicated vertical shorts feed
                final shorts = provider.allVideos.where((v) => v.categoryId == 'shorts').toList();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => KidShortsFeedScreen(
                      videos: shorts.isNotEmpty ? shorts : provider.allVideos,
                      initialIndex: 0,
                    ),
                  ),
                );
              } else {
                setState(() {
                  _selectedFilter = filter['id']!;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? KidColors.chipSelectedBg : KidColors.chipUnselectedBg,
                borderRadius: BorderRadius.circular(18), // 18px pill radius per DESIGN.md
                border: Border.all(
                  color: isSelected ? Colors.transparent : KidColors.borderDark,
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: isSelected ? KidColors.chipSelectedText : KidColors.chipUnselectedText,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // RESPONSIVE FEED (MOBILE, TABLET, PORTRAIT, LANDSCAPE)
  // ==========================================
  Widget _buildResponsiveFeed(BuildContext context, AppProvider provider, List<VideoItem> videos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTabletOrLandscape = width >= 600;

        // Tablet or Phone Landscape: Multi-column Grid
        if (isTabletOrLandscape) {
          final crossAxisCount = width > 900 ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20,
              crossAxisSpacing: 16,
              childAspectRatio: width > 900 ? 1.12 : 1.04,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoCard(
                video: video,
                downloadProgress: provider.downloadProgress[video.id],
                onTap: () => _openPlayer(context, video, videos),
                onDownloadTap: () => provider.startDownload(video),
              );
            },
          );
        }

        // Phone Portrait: Authentic Vertical Single-Column YouTube Feed
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          itemCount: (_selectedFilter == 'all' ? 1 : 0) + videos.length,
          itemBuilder: (context, index) {
            // 0. Horizontal Shorts Row when "All" is active
            if (_selectedFilter == 'all' && index == 0) {
              return _buildShortsShelf(context, provider);
            }

            final videoIndex = _selectedFilter == 'all' ? index - 1 : index;
            final video = videos[videoIndex];

            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: VideoCard(
                video: video,
                downloadProgress: provider.downloadProgress[video.id],
                onTap: () => _openPlayer(context, video, videos),
                onDownloadTap: () => provider.startDownload(video),
              ),
            );
          },
        );
      },
    );
  }

  /// Compact Horizontal Shorts & Reels Shelf (YouTube Home style)
  Widget _buildShortsShelf(BuildContext context, AppProvider provider) {
    final shorts = provider.allVideos.where((v) => v.categoryId == 'shorts').toList();
    if (shorts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shelf Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: KidColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Shorts & Reels',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => KidShortsFeedScreen(
                        videos: provider.allVideos,
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Watch all >',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: KidColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal list of compact cards
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: shorts.length,
              itemBuilder: (context, index) {
                final item = shorts[index];
                return VideoCard(
                  video: item,
                  isHorizontalCompact: true,
                  onTap: () {
                    final all = provider.allVideos;
                    final idx = all.indexWhere((v) => v.id == item.id);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => KidShortsFeedScreen(
                          videos: all,
                          initialIndex: idx >= 0 ? idx : 0,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: KidColors.borderDark, height: 1),
        ],
      ),
    );
  }

  void _openPlayer(BuildContext context, VideoItem video, List<VideoItem> playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => KidPlayerScreen(
          video: video,
          playlist: playlist,
        ),
      ),
    );
  }

  void _showAccountModal(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KidColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Profile Header
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: KidColors.surfaceDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: KidColors.borderDark, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          provider.activeProfile?.emojiAvatar ?? '🐻',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.activeProfile?.name ?? 'Kids Profile',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: KidColors.textLight,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Active Child Profile',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: KidColors.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: KidColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ProfileSelectorDialog.show(context);
                      },
                      child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: KidColors.borderDark, height: 1),
                const SizedBox(height: 8),

                // 1. Offline Mode Switch
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    provider.isOfflineOnly ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                    color: provider.isOfflineOnly ? KidColors.primary : KidColors.green,
                    size: 24,
                  ),
                  title: const Text(
                    'Offline Only (Saved Videos)',
                    style: TextStyle(fontFamily: 'Roboto', color: KidColors.textLight, fontSize: 14.5, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    provider.isOfflineOnly ? 'Showing downloaded videos only' : 'Play online and offline content',
                    style: const TextStyle(fontFamily: 'Roboto', color: KidColors.textMuted, fontSize: 12),
                  ),
                  trailing: Switch(
                    activeColor: KidColors.primary,
                    value: provider.isOfflineOnly,
                    onChanged: (val) {
                      provider.toggleOfflineOnly();
                      Navigator.pop(context);
                    },
                  ),
                ),

                // 2. Parent Dashboard & Controls
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.shield_outlined, color: KidColors.textMuted, size: 24),
                  title: const Text(
                    'Parent Dashboard & Controls',
                    style: TextStyle(fontFamily: 'Roboto', color: KidColors.textLight, fontSize: 14.5, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'PIN protected settings, media ingest, limits',
                    style: TextStyle(fontFamily: 'Roboto', color: KidColors.textMuted, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: KidColors.textMuted),
                  onTap: () {
                    Navigator.pop(context);
                    ParentGateDialog.show(context);
                  },
                ),

                // 3. Refresh Catalog
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh_rounded, color: KidColors.textMuted, size: 24),
                  title: const Text(
                    'Sync Video Catalog',
                    style: TextStyle(fontFamily: 'Roboto', color: KidColors.textLight, fontSize: 14.5, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: KidColors.textMuted),
                  onTap: () {
                    Navigator.pop(context);
                    provider.syncCatalog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<VideoItem> _filterVideos(AppProvider provider) {
    List<VideoItem> list = provider.allVideos;

    if (_selectedFilter == 'favorites') {
      list = provider.favoriteVideos;
    } else if (_selectedFilter == 'downloaded') {
      list = provider.downloadedVideos;
    } else if (_selectedFilter != 'all') {
      list = provider.getVideosForCategory(_selectedFilter);
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((v) => v.title.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline_rounded, size: 64, color: KidColors.borderDark),
            const SizedBox(height: 16),
            const Text(
              'No Videos Found',
              style: TextStyle(fontFamily: 'Roboto', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No videos match "$_searchQuery".'
                  : 'No videos available in this category yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Roboto', color: KidColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

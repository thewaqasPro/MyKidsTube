import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/video_item.dart';
import '../models/category_item.dart';
import '../utils/constants.dart';
import '../widgets/video_tile.dart';
import 'kid_player_screen.dart';
import 'parent_gate_dialog.dart';
import 'profile_selector_dialog.dart';

class KidHomeScreen extends StatelessWidget {
  const KidHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: KidColors.bgDark,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [KidColors.primary, KidColors.accent]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'KidsTube',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
              // Active Child Profile Switcher (e.g. 🐻 Maya)
              if (provider.availableProfiles.isNotEmpty)
                GestureDetector(
                  onTap: () => ProfileSelectorDialog.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: KidColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KidColors.borderDark),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.activeProfile?.emojiAvatar ?? '🐻',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          provider.activeProfile?.name ?? 'Kids',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Offline toggle button
              IconButton(
                tooltip: provider.isOfflineOnly ? 'Show All' : 'Offline Only',
                icon: Icon(
                  provider.isOfflineOnly ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                  color: provider.isOfflineOnly ? KidColors.accent : KidColors.green,
                ),
                onPressed: () => provider.toggleOfflineOnly(),
              ),

              // Parent Gate Icon
              IconButton(
                tooltip: 'Parents',
                icon: const Icon(Icons.shield_rounded, color: KidColors.textMuted),
                onPressed: () => ParentGateDialog.show(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            color: KidColors.primary,
            backgroundColor: KidColors.cardDark,
            onRefresh: () => provider.syncCatalog(),
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: KidColors.primary))
                : (provider.allVideos.isEmpty
                    ? _buildEmptyState(context, provider)
                    : _buildContent(context, provider)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_library_outlined, size: 72, color: KidColors.surfaceDark),
              const SizedBox(height: 16),
              const Text(
                'No Videos Yet!',
                style: TextStyle(
                  color: KidColors.textLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the lock icon in the top right corner\nto paste links and add videos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: KidColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KidColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ParentGateDialog.show(context),
                icon: const Icon(Icons.add_link_rounded, color: Colors.white),
                label: const Text('Add Videos as Parent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AppProvider provider) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // 1. Downloaded Shelf (Pinned at top if any downloaded videos exist)
        if (provider.downloadedVideos.isNotEmpty && !provider.isOfflineOnly)
          _buildShelf(
            context,
            provider,
            title: 'Downloaded & Ready to Watch',
            icon: Icons.offline_pin_rounded,
            iconColor: KidColors.green,
            videos: provider.downloadedVideos,
          ),

        // 2. Category Shelves
        for (final category in provider.categories) ...[
          Builder(builder: (context) {
            final categoryVideos = provider.getVideosForCategory(category.id);
            if (categoryVideos.isEmpty) return const SizedBox.shrink();

            return _buildShelf(
              context,
              provider,
              title: category.name,
              icon: _getCategoryIcon(category.icon),
              iconColor: KidColors.primary,
              videos: categoryVideos,
            );
          }),
        ],

        // 3. Extra spacer at bottom
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildShelf(
    BuildContext context,
    AppProvider provider, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<VideoItem> videos,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shelf Title Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: KidColors.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${videos.length}',
                  style: const TextStyle(color: KidColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Horizontal scrolling video cards
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                final progress = provider.downloadProgress[video.id];

                return VideoTile(
                  video: video,
                  downloadProgress: progress,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => KidPlayerScreen(video: video),
                      ),
                    );
                  },
                  onDownloadTap: () {
                    provider.startDownload(video);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'tv':
        return Icons.live_tv_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'bedtime':
        return Icons.nightlight_round;
      default:
        return Icons.category_rounded;
    }
  }
}

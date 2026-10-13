import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_item.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'kid_player_screen.dart';
import '../services/youtube_metadata_service.dart';

class ParentMediaLibraryScreen extends StatefulWidget {
  const ParentMediaLibraryScreen({super.key});

  @override
  State<ParentMediaLibraryScreen> createState() => _ParentMediaLibraryScreenState();
}

class _ParentMediaLibraryScreenState extends State<ParentMediaLibraryScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'cartoons';
  String _selectedQuality = '720p';
  bool _isIngesting = false;
  bool _showAddForm = false;

  // Multi-selection state for bulk actions
  bool _isSelectionMode = false;
  final Set<String> _selectedVideoIds = {};
  String _filterCategory = 'all';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.categories.isNotEmpty) {
      _selectedCategory = provider.categories.first.id;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitIngest() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isIngesting = true);
    final provider = Provider.of<AppProvider>(context, listen: false);

    // 1. Fetch metadata via oEmbed for instant local addition
    final meta = await YouTubeMetadataService().fetchMetadata(url);
    if (meta != null) {
      final video = meta.toVideoItem(categoryId: _selectedCategory);
      await provider.addStandaloneVideo(video);
    }

    // 2. Also try VPS ingestion in background if online
    try {
      await provider.submitUrlForIngestion(
        url,
        _selectedCategory,
        quality: _selectedQuality,
      );
    } catch (_) {}

    setState(() => _isIngesting = false);

    if (mounted) {
      _urlController.clear();
      setState(() => _showAddForm = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video added to library!'),
          backgroundColor: KidColors.mint,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteVideos(List<String> ids) async {
    if (ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KidColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KidColors.borderDark),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: KidColors.red, size: 24),
            const SizedBox(width: 10),
            Text(
              ids.length == 1 ? 'Delete Video?' : 'Delete ${ids.length} Videos?',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          ids.length == 1
              ? 'This will permanently remove the video from the server and delete any local cached files.'
              : 'This will permanently remove ${ids.length} videos from the server and purge their local cached files.',
          style: const TextStyle(color: KidColors.textMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KidColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final ok = await provider.deleteVideosFromCatalog(ids);
      setState(() {
        _selectedVideoIds.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Deleted successfully!' : 'Deleted locally (server may be offline).'),
            backgroundColor: KidColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleSelectAll(List<VideoItem> currentList) {
    setState(() {
      if (_selectedVideoIds.length == currentList.length) {
        _selectedVideoIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedVideoIds.addAll(currentList.map((v) => v.id));
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final query = _searchController.text.trim().toLowerCase();
        var videos = provider.allVideos;

        if (_filterCategory != 'all') {
          videos = videos.where((v) => v.categoryId == _filterCategory).toList();
        }

        if (query.isNotEmpty) {
          videos = videos.where((v) {
            final titleMatch = v.title.toLowerCase().contains(query);
            final channelMatch = (v.channelName ?? '').toLowerCase().contains(query);
            return titleMatch || channelMatch;
          }).toList();
        }

        return Scaffold(
          backgroundColor: KidColors.bgDark,
          appBar: AppBar(
            title: Text(
              _isSelectionMode
                  ? '${_selectedVideoIds.length} Selected'
                  : 'Media Library (${provider.allVideos.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            backgroundColor: KidColors.bgDark,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(_isSelectionMode ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                if (_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedVideoIds.clear();
                  });
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              if (_isSelectionMode) ...[
                IconButton(
                  tooltip: 'Select All',
                  icon: Icon(
                    _selectedVideoIds.length == videos.length
                        ? Icons.select_all_rounded
                        : Icons.deselect_rounded,
                  ),
                  onPressed: () => _toggleSelectAll(videos),
                ),
                IconButton(
                  tooltip: 'Delete Selected',
                  icon: const Icon(Icons.delete_outline_rounded, color: KidColors.red),
                  onPressed: _selectedVideoIds.isEmpty
                      ? null
                      : () => _confirmDeleteVideos(_selectedVideoIds.toList()),
                ),
              ] else ...[
                IconButton(
                  tooltip: _showAddForm ? 'Close Add Video' : 'Add Video by URL',
                  icon: Icon(_showAddForm ? Icons.remove_circle_outline : Icons.add_circle_outline, color: KidColors.primary),
                  onPressed: () => setState(() => _showAddForm = !_showAddForm),
                ),
                IconButton(
                  tooltip: 'Select Videos',
                  icon: const Icon(Icons.checklist_rounded),
                  onPressed: () => setState(() => _isSelectionMode = true),
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              // Ingest Form (Collapsible / Toggleable)
              if (_showAddForm) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KidColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KidColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.add_link_rounded, color: KidColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add Video to Catalog',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'https://youtube.com/watch?v=... or shorts/...',
                          hintStyle: const TextStyle(color: KidColors.textMuted),
                          filled: true,
                          fillColor: KidColors.bgDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: KidColors.borderDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: provider.categories.any((c) => c.id == _selectedCategory)
                                  ? _selectedCategory
                                  : (provider.categories.isNotEmpty ? provider.categories.first.id : 'cartoons'),
                              dropdownColor: KidColors.cardDark,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Category',
                                labelStyle: const TextStyle(color: KidColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                filled: true,
                                fillColor: KidColors.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: KidColors.borderDark),
                                ),
                              ),
                              items: provider.categories.map((c) {
                                return DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedQuality,
                              dropdownColor: KidColors.cardDark,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Quality',
                                labelStyle: const TextStyle(color: KidColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                filled: true,
                                fillColor: KidColors.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: KidColors.borderDark),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: '720p', child: Text('720p')),
                                DropdownMenuItem(value: '480p', child: Text('480p')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedQuality = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KidColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isIngesting ? null : _submitIngest,
                          icon: _isIngesting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                          label: Text(
                            _isIngesting ? 'Queuing on Server...' : 'Download & Ingest to Library',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Search Bar & Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search videos or channels...',
                    hintStyle: const TextStyle(color: KidColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: KidColors.textMuted, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: KidColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: KidColors.cardDark,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: KidColors.borderDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: KidColors.borderDark),
                    ),
                  ),
                ),
              ),

              // Category Filter Horizontal Pills
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryPill('all', 'All Videos (${provider.allVideos.length})'),
                    ...provider.categories.map((cat) {
                      final count = provider.allVideos.where((v) => v.categoryId == cat.id).length;
                      return _buildCategoryPill(cat.id, '${cat.name} ($count)');
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Video List
              Expanded(
                child: videos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.video_library_outlined, color: KidColors.textMuted, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              query.isNotEmpty ? 'No videos matching "$query"' : 'No videos found in this category',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: videos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          final isSelected = _selectedVideoIds.contains(video.id);

                          return _buildVideoRowItem(
                            context: context,
                            video: video,
                            provider: provider,
                            isSelected: isSelected,
                            allList: videos,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryPill(String id, String label) {
    final isSelected = _filterCategory == id;
    return GestureDetector(
      onTap: () => setState(() => _filterCategory = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KidColors.primary : KidColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? KidColors.primary : KidColors.borderDark),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : KidColors.textMuted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoRowItem({
    required BuildContext context,
    required VideoItem video,
    required AppProvider provider,
    required bool isSelected,
    required List<VideoItem> allList,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? KidColors.primary.withValues(alpha: 0.12) : KidColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? KidColors.primary : KidColors.borderDark,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedVideoIds.remove(video.id);
                if (_selectedVideoIds.isEmpty) _isSelectionMode = false;
              } else {
                _selectedVideoIds.add(video.id);
              }
            });
          } else {
            // Open player preview
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => KidPlayerScreen(
                  video: video,
                  playlist: allList,
                ),
              ),
            );
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedVideoIds.add(video.id);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Selection Checkbox or Thumbnail
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  activeColor: KidColors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedVideoIds.add(video.id);
                      } else {
                        _selectedVideoIds.remove(video.id);
                        if (_selectedVideoIds.isEmpty) _isSelectionMode = false;
                      }
                    });
                  },
                ),
                const SizedBox(width: 4),
              ],

              // Thumbnail with duration badge
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 90,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: KidColors.bgDark),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.durationFormatted,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      if (video.isShort) ...[
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: KidColors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SHORTS',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title and Channel / Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          video.channelName ?? 'KidsTube',
                          style: const TextStyle(color: KidColors.textMuted, fontSize: 11.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        if (video.isOfflineReady) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: KidColors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OFFLINE',
                              style: TextStyle(color: KidColors.green, fontSize: 9.5, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions: Download & Delete
              if (!_isSelectionMode) ...[
                IconButton(
                  tooltip: video.isOfflineReady ? 'Downloaded' : 'Download Offline',
                  icon: Icon(
                    video.isOfflineReady ? Icons.download_done_rounded : Icons.download_rounded,
                    color: video.isOfflineReady ? KidColors.green : Colors.white70,
                    size: 20,
                  ),
                  onPressed: () async {
                    if (video.isOfflineReady) {
                      provider.deleteDownloaded(video);
                    } else {
                      final err = await provider.startDownload(video);
                      if (err != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err),
                            backgroundColor: KidColors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Delete Video',
                  icon: const Icon(Icons.delete_outline_rounded, color: KidColors.red, size: 20),
                  onPressed: () => _confirmDeleteVideos([video.id]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_provider.dart';
import '../services/youtube_explorer_service.dart';
import '../models/followed_channel.dart';

enum SearchMode {
  channel,
  keyword,
}

class ParentYouTubeSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final SearchMode? initialMode;
  final bool isEmbedded;
  final VoidCallback? onBack;

  const ParentYouTubeSearchScreen({
    super.key,
    this.initialQuery,
    this.initialMode,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  State<ParentYouTubeSearchScreen> createState() => _ParentYouTubeSearchScreenState();
}

class _ParentYouTubeSearchScreenState extends State<ParentYouTubeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeExplorerService _explorerService = YouTubeExplorerService();

  SearchMode _searchMode = SearchMode.channel;
  bool _isLoading = false;
  String? _errorMessage;

  YouTubeChannelInfo? _channelInfo;
  List<YouTubeSearchResult> _results = [];
  final Set<String> _selectedVideoIds = {};
  final Set<String> _locallyAddedIds = {};

  String _targetCategory = 'cartoons';

  final List<String> _channelSuggestions = [
    '@peppapig',
    '@CoComelon',
    'Ms Rachel',
    'Numberblocks',
    'Super Simple Songs',
    'Bluey',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      _searchMode = widget.initialMode!;
    }
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.categories.isNotEmpty) {
      _targetCategory = provider.categories.first.id;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _explorerService.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _channelInfo = null;
      _results = [];
      _selectedVideoIds.clear();
    });

    try {
      if (_searchMode == SearchMode.channel) {
        final channelResult = await _explorerService.getChannelVideos(query);
        if (!mounted) return;

        if (channelResult != null && channelResult.videos.isNotEmpty) {
          setState(() {
            _channelInfo = channelResult.channel;
            _results = channelResult.videos;
            _isLoading = false;
          });
        } else {
          // Fallback to keyword search if channel wasn't found directly
          final fallbackResults = await _explorerService.searchVideos(query);
          if (!mounted) return;
          setState(() {
            _results = fallbackResults;
            _isLoading = false;
            if (fallbackResults.isEmpty) {
              _errorMessage = 'No videos or channels found for "$query".';
            }
          });
        }
      } else {
        final searchResults = await _explorerService.searchVideos(query);
        if (!mounted) return;
        setState(() {
          _results = searchResults;
          _isLoading = false;
          if (searchResults.isEmpty) {
            _errorMessage = 'No YouTube videos found matching "$query".';
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load videos. Please check your internet connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _addSingleVideo(YouTubeSearchResult video) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final videoItem = video.toVideoItem(categoryId: _targetCategory);

    await provider.addStandaloneVideo(videoItem);
    setState(() {
      _locallyAddedIds.add(video.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Added "${video.title}" to catalog',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addSelectedVideos() async {
    if (_selectedVideoIds.isEmpty) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final toAdd = _results
        .where((v) => _selectedVideoIds.contains(v.id))
        .map((v) => v.toVideoItem(categoryId: _targetCategory))
        .toList();

    await provider.addStandaloneVideos(toAdd);

    setState(() {
      _locallyAddedIds.addAll(_selectedVideoIds);
      _selectedVideoIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Text('Added ${toAdd.length} videos to $_targetCategory'),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedVideoIds.length == _results.length) {
        _selectedVideoIds.clear();
      } else {
        _selectedVideoIds.addAll(_results.map((v) => v.id));
      }
    });
  }

  bool _isVideoInLibrary(String videoId, AppProvider provider) {
    if (_locallyAddedIds.contains(videoId)) return true;
    return provider.allVideos.any((v) => v.id == videoId || v.youtubeId == videoId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final content = Column(
          children: [
            _buildSearchBar(),
            _buildControlsBar(provider),
            Expanded(
              child: _buildBody(provider),
            ),
            if (_selectedVideoIds.isNotEmpty) _buildBottomBatchBar(),
          ],
        );

        if (widget.isEmbedded) {
          return content;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            elevation: 0,
            title: const Text(
              'Search & Add YouTube Videos',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: _searchMode == SearchMode.channel
                    ? 'Enter channel handle or name (e.g. @peppapig)...'
                    : 'Search YouTube (e.g. dinosaur songs, phonics)...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 22),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.redAccent),
                      onPressed: _performSearch,
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Search Mode Segmented Switch
          Row(
            children: [
              _buildModeChip(
                label: 'Search Channel',
                icon: Icons.tv_rounded,
                mode: SearchMode.channel,
              ),
              const SizedBox(width: 8),
              _buildModeChip(
                label: 'Keyword Search',
                icon: Icons.youtube_searched_for_rounded,
                mode: SearchMode.keyword,
              ),
            ],
          ),

          // Quick Suggestion Chips (if search is empty)
          if (_results.isEmpty && !_isLoading) ...[
            const SizedBox(height: 12),
            const Text(
              'Popular Kid Channels:',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _channelSuggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(suggestion),
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      backgroundColor: const Color(0xFF2C2C2C),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () {
                        _searchController.text = suggestion;
                        _searchMode = SearchMode.channel;
                        _performSearch();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required IconData icon,
    required SearchMode mode,
  }) {
    final isSelected = _searchMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _searchMode = mode;
        });
        if (_searchController.text.isNotEmpty) {
          _performSearch();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent.withValues(alpha: 0.2) : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.redAccent : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.redAccent : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsBar(AppProvider provider) {
    if (_results.isEmpty && !_isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF161616),
      child: Row(
        children: [
          // Select All Checkbox
          if (_results.isNotEmpty) ...[
            InkWell(
              onTap: _toggleSelectAll,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedVideoIds.length == _results.length && _results.isNotEmpty,
                    onChanged: (_) => _toggleSelectAll(),
                    activeColor: Colors.redAccent,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    'Select All (${_results.length})',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],

          // Category Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.categories.any((c) => c.id == _targetCategory)
                    ? _targetCategory
                    : (provider.categories.isNotEmpty ? provider.categories.first.id : 'cartoons'),
                dropdownColor: const Color(0xFF242424),
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                items: provider.categories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _targetCategory = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppProvider provider) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.redAccent),
            SizedBox(height: 16),
            Text(
              'Loading videos from YouTube...',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 54, color: Colors.white38),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.video_library_outlined, size: 48, color: Colors.white38),
              ),
              const SizedBox(height: 16),
              const Text(
                'Search YouTube Channels or Topics',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find approved kid-friendly videos and add them to your child’s catalog with a single tap.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: (_channelInfo != null ? 1 : 0) + _results.length,
      itemBuilder: (context, index) {
        if (_channelInfo != null && index == 0) {
          return _buildChannelHeaderCard(_channelInfo!);
        }

        final videoIndex = _channelInfo != null ? index - 1 : index;
        final video = _results[videoIndex];
        final isInLibrary = _isVideoInLibrary(video.id, provider);
        final isSelected = _selectedVideoIds.contains(video.id);

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.redAccent : Colors.white.withValues(alpha: 0.06),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedVideoIds.remove(video.id);
                } else {
                  _selectedVideoIds.add(video.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Multi-select Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedVideoIds.add(video.id);
                        } else {
                          _selectedVideoIds.remove(video.id);
                        }
                      });
                    },
                    activeColor: Colors.redAccent,
                    visualDensity: VisualDensity.compact,
                  ),

                  // Thumbnail with duration badge
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 105,
                          height: 65,
                          child: CachedNetworkImage(
                            imageUrl: video.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.black26),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.black45,
                              child: const Icon(Icons.broken_image_rounded, size: 24, color: Colors.white38),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video.durationFormatted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title & Channel info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.channelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 1-Tap Add Action Button
                  if (isInLibrary)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.greenAccent, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Added',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => _addSingleVideo(video),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(60, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelHeaderCard(YouTubeChannelInfo ch) {
    final provider = Provider.of<AppProvider>(context);
    final isFollowed = provider.isChannelFollowed(ch.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFollowed ? Colors.amber.withValues(alpha: 0.5) : Colors.white12,
          width: isFollowed ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          if (ch.logoUrl != null && ch.logoUrl!.isNotEmpty)
            CircleAvatar(
              radius: 22,
              backgroundImage: CachedNetworkImageProvider(ch.logoUrl!),
            )
          else
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.tv_rounded, color: Colors.white),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ch.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_results.length} uploads loaded • Tap + to add directly',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              if (isFollowed) {
                await provider.unfollowChannel(ch.id);
              } else {
                await provider.followChannel(
                  FollowedChannel(
                    channelId: ch.id,
                    title: ch.title,
                    handle: ch.title,
                    logoUrl: ch.logoUrl,
                    addedAt: DateTime.now().millisecondsSinceEpoch,
                  ),
                );
              }
            },
            icon: Icon(
              isFollowed ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
              size: 15,
              color: isFollowed ? Colors.greenAccent : Colors.white70,
            ),
            label: Text(
              isFollowed ? 'Following' : 'Follow',
              style: TextStyle(
                fontSize: 12,
                color: isFollowed ? Colors.greenAccent : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: isFollowed ? Colors.greenAccent : Colors.white24,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBatchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '${_selectedVideoIds.length} Selected',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addSelectedVideos,
              icon: const Icon(Icons.playlist_add_check_rounded, size: 20),
              label: Text('Add ${_selectedVideoIds.length} Videos to $_targetCategory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

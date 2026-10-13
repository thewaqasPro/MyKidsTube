import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';
import '../providers/app_provider.dart';
import '../services/youtube_metadata_service.dart';
import '../utils/constants.dart';

class AddVideoSheet extends StatefulWidget {
  const AddVideoSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddVideoSheet(),
    );
  }

  @override
  State<AddVideoSheet> createState() => _AddVideoSheetState();
}

class _AddVideoSheetState extends State<AddVideoSheet> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final YouTubeMetadataService _metadataService = YouTubeMetadataService();

  bool _isLoading = false;
  String? _errorMessage;
  YouTubeMetadata? _metadata;
  String _selectedCategory = 'cartoons';
  String _selectedProfile = 'kids_all';

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
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _urlController.text = text;
      _onUrlSubmitted(text);
    }
  }

  Future<void> _onUrlSubmitted(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final id = YouTubeMetadataService.extractVideoId(trimmed);
    if (id == null) {
      setState(() {
        _errorMessage = 'Please enter a valid YouTube video or short URL';
        _metadata = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final meta = await _metadataService.fetchMetadata(trimmed);
    if (!mounted) return;

    if (meta != null) {
      setState(() {
        _metadata = meta;
        _titleController.text = meta.title;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'Could not load video information. Please check the link.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveVideo() async {
    if (_metadata == null) return;

    final title = _titleController.text.trim().isEmpty ? _metadata!.title : _titleController.text.trim();
    final video = VideoItem(
      id: _metadata!.id,
      youtubeId: _metadata!.id,
      title: title,
      channelName: _metadata!.authorName,
      categoryId: _selectedCategory,
      profileId: _selectedProfile,
      sourceUrl: _metadata!.sourceUrl,
      streamUrl: 'https://www.youtube.com/watch?v=${_metadata!.id}',
      thumbnailUrl: _metadata!.thumbnailUrl,
      status: 'embed',
      durationFormatted: _metadata!.isShort ? 'Short' : 'YouTube',
      quality: '720p',
    );

    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.addStandaloneVideo(video);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Added "$title" to KidsTube!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: KidColors.mint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final provider = Provider.of<AppProvider>(context);
    final categories = provider.categories;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 20,
      ),
      decoration: const BoxDecoration(
        color: KidColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: KidColors.borderDark, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: KidColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Header (YouTube Style)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: KidColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Add YouTube Video',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, color: KidColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // URL Input with Paste Button
            Container(
              decoration: BoxDecoration(
                color: KidColors.bgDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _errorMessage != null ? KidColors.red : KidColors.borderDark,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.link_rounded, color: KidColors.textMuted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(fontFamily: 'Roboto', color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Paste YouTube URL or Video ID...',
                        hintStyle: TextStyle(fontFamily: 'Roboto', color: KidColors.textMuted, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _onUrlSubmitted,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: KidColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: _handlePaste,
                    icon: const Icon(Icons.content_paste_rounded, size: 16),
                    label: const Text('Paste', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: KidColors.red, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],

            // Loading Indicator
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: KidColors.primary),
                ),
              ),
            ],

            // Video Preview Card (Shows once fetched)
            if (_metadata != null && !_isLoading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KidColors.cardElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KidColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail Preview with Type Pill
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: _metadata!.isShort ? 9 / 16 : 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: _metadata!.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: KidColors.bgDark,
                                child: const Icon(Icons.broken_image_rounded, color: KidColors.textMuted),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: KidColors.durationBadgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _metadata!.isShort ? Icons.bolt_rounded : Icons.smart_display_rounded,
                                  color: _metadata!.isShort ? KidColors.sun : KidColors.primary,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _metadata!.isShort ? 'Short' : 'Video',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Editable Title
                    const Text(
                      'Video Title',
                      style: TextStyle(color: KidColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: KidColors.bgDark,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: KidColors.borderDark),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: KidColors.borderDark),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Channel Name display
                    Row(
                      children: [
                        const Icon(Icons.account_circle_rounded, color: KidColors.textMuted, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _metadata!.authorName,
                          style: const TextStyle(color: KidColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Category Selector (YouTube Pills)
              const Text(
                'Category',
                style: TextStyle(color: KidColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: KidColors.chipSelectedBg,
                        backgroundColor: KidColors.chipUnselectedBg,
                        labelStyle: TextStyle(
                          color: isSelected ? KidColors.chipSelectedText : KidColors.chipUnselectedText,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (_) => setState(() => _selectedCategory = cat.id),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Profile Selector (if multiple child profiles exist)
              if (provider.availableProfiles.length > 1) ...[
                const SizedBox(height: 14),
                const Text(
                  'Assign to Profile',
                  style: TextStyle(color: KidColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProfile,
                  dropdownColor: KidColors.cardElevated,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: KidColors.bgDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: KidColors.borderDark),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'kids_all', child: Text('All Kids')),
                    ...provider.availableProfiles.map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProfile = val);
                  },
                ),
              ],

              const SizedBox(height: 20),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KidColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveVideo,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Add Video to KidsTube',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

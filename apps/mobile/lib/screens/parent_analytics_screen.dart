import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/child_avatar.dart';

class ParentAnalyticsScreen extends StatefulWidget {
  const ParentAnalyticsScreen({super.key});

  @override
  State<ParentAnalyticsScreen> createState() => _ParentAnalyticsScreenState();
}

class _ParentAnalyticsScreenState extends State<ParentAnalyticsScreen> {
  bool _isLoading = true;
  bool _isSyncingCloud = false;
  String _selectedProfileId = 'all';
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final data = await provider.getWatchAnalytics(profileId: _selectedProfileId);
    if (mounted) {
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _syncToCloud() async {
    setState(() => _isSyncingCloud = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final res = await provider.syncWatchEventsToServer();
    await _loadAnalytics();
    if (mounted) {
      setState(() => _isSyncingCloud = false);
      if (res['success'] == true) {
        final count = res['synced_count'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0 ? 'Synced $count watch sessions to Cloudflare server!' : 'Everything is already synced!'),
            backgroundColor: KidColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${res['error'] ?? 'Server unreachable'}'),
            backgroundColor: KidColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSecs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSecs}s';
    } else {
      return '${remainingSecs}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profiles = provider.availableProfiles;

    final todaySecs = (_analytics['today_seconds'] as num?)?.toInt() ?? 0;
    final totalSecs = (_analytics['total_seconds'] as num?)?.toInt() ?? 0;
    final totalSessions = (_analytics['total_sessions'] as num?)?.toInt() ?? 0;
    final completedCount = (_analytics['completed_count'] as num?)?.toInt() ?? 0;
    final skippedCount = (_analytics['skipped_count'] as num?)?.toInt() ?? 0;
    final completionRate = (_analytics['completion_rate'] as num?)?.toInt() ?? 0;
    final skipRate = (_analytics['skip_rate'] as num?)?.toInt() ?? 0;
    final unsyncedCount = (_analytics['unsynced_count'] as num?)?.toInt() ?? 0;
    final dailyBreakdown = (_analytics['daily_breakdown'] as List?) ?? [];
    final lovedVideos = (_analytics['loved_videos'] as List?) ?? [];
    final skippedVideos = (_analytics['skipped_videos'] as List?) ?? [];
    final categoryBreakdown = (_analytics['category_breakdown'] as List?) ?? [];

    final partialCount = (_analytics['partial_count'] as num?)?.toInt() ?? 0;
    final partialRate = (_analytics['partial_rate'] as num?)?.toInt() ?? 0;
    final retentionFunnel = (_analytics['retention_funnel'] as List?) ?? [];

    return Scaffold(
      backgroundColor: KidColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'Watch Time & Intelligence',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: KidColors.bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Analytics',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: KidColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Child Profile Filter Selector Chips
                  _buildProfileFilterSelector(profiles),

                  const SizedBox(height: 16),

                  // 2. Cloudflare Zero-Quota Notice
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KidColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: KidColors.accent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed_rounded, color: KidColors.accent, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Local-First Analytics Active',
                                style: TextStyle(color: KidColors.accent, fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Data is recorded in local device SQLite without network requests. Cloudflare free quota is preserved 100%.',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Executive KPI Cards (Web Studio Parity)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Screen Time',
                          value: _formatSeconds(totalSecs),
                          subtitle: 'Today ${_formatSeconds(todaySecs)} • $totalSessions sessions',
                          icon: Icons.schedule_rounded,
                          accentColor: KidColors.sky,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Captured Attention',
                          value: '$completionRate%',
                          subtitle: 'Completed ($completedCount) ≥75%',
                          icon: Icons.check_circle_outline_rounded,
                          accentColor: KidColors.mint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Quick Pass / Bounce',
                          value: '$skipRate%',
                          subtitle: 'Skipped ($skippedCount) <10s',
                          icon: Icons.warning_amber_rounded,
                          accentColor: KidColors.coral,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Partial Watch',
                          value: '$partialRate%',
                          subtitle: 'Partial ($partialCount) 15%–75%',
                          icon: Icons.play_circle_outline_rounded,
                          accentColor: KidColors.sun,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3b. Attention Funnel & Category Breakdown (Web Studio Parity)
                  if (retentionFunnel.isNotEmpty) ...[
                    _buildAttentionFunnelSection(retentionFunnel, categoryBreakdown),
                    const SizedBox(height: 20),
                  ],

                  // 4. Cloud Sync Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: KidColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KidColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.cloud_sync_rounded, color: KidColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Server Synchronization',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (unsyncedCount > 0 ? KidColors.yellow : KidColors.green).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (unsyncedCount > 0 ? KidColors.yellow : KidColors.green).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                unsyncedCount > 0 ? '$unsyncedCount UNSYNCED' : 'UP TO DATE',
                                style: TextStyle(
                                  color: unsyncedCount > 0 ? KidColors.yellow : KidColors.green,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          unsyncedCount > 0
                              ? 'You have $unsyncedCount local watch sessions waiting to sync to your Cloudflare D1 database.'
                              : 'All watch events are synchronized with your cloud database.',
                          style: const TextStyle(color: KidColors.textMuted, fontSize: 12.5),
                        ),
                        const SizedBox(height: 14),

                        // Single-row button for Sync to Cloud
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KidColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: _isSyncingCloud ? null : _syncToCloud,
                            icon: _isSyncingCloud
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.cloud_upload_rounded, size: 18),
                            label: Text(
                              _isSyncingCloud ? 'Syncing in Batch...' : 'Sync to Cloud Server Now',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 5. 7-Day Screen Time Chart
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: KidColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KidColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bar_chart_rounded, color: KidColors.accent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '7-Day Watch Trend',
                              style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildWeeklyChart(dailyBreakdown),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 6. Content Kids Love Most Leaderboard
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: KidColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KidColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: KidColors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Content Kids Love Most',
                              style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: KidColors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'High Completion',
                                style: TextStyle(color: KidColors.green, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (lovedVideos.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                'No completed watch sessions recorded yet.',
                                style: TextStyle(color: KidColors.textMuted, fontSize: 13),
                              ),
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lovedVideos.length,
                            separatorBuilder: (_, __) => const Divider(color: KidColors.borderDark, height: 16),
                            itemBuilder: (context, idx) {
                              final v = lovedVideos[idx];
                              final title = v['title']?.toString() ?? 'Video';
                              final thumbnailUrl = v['thumbnail_url']?.toString() ?? '';
                              final channelName = v['channel_name']?.toString() ?? 'WonderKids';
                              final secs = (v['total_seconds'] as num?)?.toInt() ?? 0;
                              final views = (v['views'] as num?)?.toInt() ?? 1;
                              final completed = (v['completed_count'] as num?)?.toInt() ?? 0;
                              final completionPct = (v['completion_pct'] as num?)?.toInt() ?? 0;

                              final colors = [
                                const Color(0xFFFFD700), // Gold
                                const Color(0xFFC0C0C0), // Silver
                                const Color(0xFFCD7F32), // Bronze
                              ];
                              final badgeColor = idx < colors.length ? colors[idx] : Colors.white54;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '#${idx + 1}',
                                        style: TextStyle(
                                          color: badgeColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 58,
                                      height: 34,
                                      color: KidColors.bgDark,
                                      child: thumbnailUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: thumbnailUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(color: KidColors.bgDark),
                                              errorWidget: (_, __, ___) => const Icon(
                                                Icons.play_circle_outline_rounded,
                                                color: Colors.white24,
                                                size: 18,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.play_circle_outline_rounded,
                                              color: Colors.white24,
                                              size: 18,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$channelName • $views plays • $completed ($completionPct%) finished',
                                          style: const TextStyle(color: KidColors.textMuted, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatSeconds(secs),
                                    style: const TextStyle(color: KidColors.green, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 7. Passed Quickly (< 10s) Abandonment List
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: KidColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KidColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fast_forward_rounded, color: KidColors.yellow, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Passed Quickly (< 10s)',
                              style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: KidColors.yellow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Low Interest',
                                style: TextStyle(color: KidColors.yellow, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (skippedVideos.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                'No quick skips recorded. Kids are enjoying their content!',
                                style: TextStyle(color: KidColors.textMuted, fontSize: 13),
                              ),
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: skippedVideos.length,
                            separatorBuilder: (_, __) => const Divider(color: KidColors.borderDark, height: 16),
                            itemBuilder: (context, idx) {
                              final v = skippedVideos[idx];
                              final title = v['title']?.toString() ?? 'Video';
                              final thumbnailUrl = v['thumbnail_url']?.toString() ?? '';
                              final channelName = v['channel_name']?.toString() ?? 'WonderKids';
                              final skipCount = (v['skip_count'] as num?)?.toInt() ?? 1;
                              final avgSecs = (v['avg_seconds'] as num?)?.toDouble() ?? 0.0;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: KidColors.yellow.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.fast_forward_rounded, color: KidColors.yellow, size: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 58,
                                      height: 34,
                                      color: KidColors.bgDark,
                                      child: thumbnailUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: thumbnailUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(color: KidColors.bgDark),
                                              errorWidget: (_, __, ___) => const Icon(
                                                Icons.play_circle_outline_rounded,
                                                color: Colors.white24,
                                                size: 18,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.play_circle_outline_rounded,
                                              color: Colors.white24,
                                              size: 18,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$channelName • ~${avgSecs.toStringAsFixed(1)}s avg before skip',
                                          style: const TextStyle(color: KidColors.textMuted, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: KidColors.yellow.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: KidColors.yellow.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '$skipCount skip${skipCount == 1 ? '' : 's'}',
                                      style: const TextStyle(color: KidColors.yellow, fontWeight: FontWeight.w700, fontSize: 11),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 8. Category Breakdown
                  if (categoryBreakdown.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: KidColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KidColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pie_chart_outline_rounded, color: KidColors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Category Breakdown',
                                style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...categoryBreakdown.map((cat) {
                            final catId = cat['category_id']?.toString() ?? 'other';
                            final secs = (cat['total_seconds'] as num?)?.toInt() ?? 0;
                            final ratio = totalSecs > 0 ? (secs / totalSecs) : 0.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        catId.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      Text(
                                        '${_formatSeconds(secs)} (${(ratio * 100).toStringAsFixed(0)}%)',
                                        style: const TextStyle(color: KidColors.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio.clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: KidColors.bgDark,
                                      valueColor: const AlwaysStoppedAnimation<Color>(KidColors.green),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProfileFilterSelector(List<dynamic> profiles) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All Children chip
          _buildFilterChip(
            id: 'all',
            label: 'All Children',
            icon: Icons.groups_rounded,
            isSelected: _selectedProfileId == 'all',
          ),
          const SizedBox(width: 8),
          ...profiles.map((p) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                id: p.id,
                label: p.name,
                avatarIcon: p.avatarIcon,
                isSelected: _selectedProfileId == p.id,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    IconData? icon,
    String? avatarIcon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (_selectedProfileId != id) {
          setState(() => _selectedProfileId = id);
          _loadAnalytics();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KidColors.primary : KidColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? KidColors.primary : KidColors.borderDark,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: KidColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatarIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChildAvatar(avatarIcon: avatarIcon, radius: 10, showBorder: false),
              )
            else if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: isSelected ? Colors.white : KidColors.textLight,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: KidColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KidColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: KidColors.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: accentColor.withValues(alpha: 0.85), fontSize: 10.5, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<dynamic> days) {
    if (days.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No weekly data yet', style: TextStyle(color: KidColors.textMuted)),
        ),
      );
    }

    int maxSecs = 1;
    for (final d in days) {
      final s = (d['seconds'] as num?)?.toInt() ?? 0;
      if (s > maxSecs) maxSecs = s;
    }

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final label = day['day_label']?.toString() ?? '';
          final secs = (day['seconds'] as num?)?.toInt() ?? 0;
          final ratio = (secs / maxSecs).clamp(0.08, 1.0);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  secs > 0 ? '${(secs / 60).round()}m' : '',
                  style: const TextStyle(color: KidColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 70 * ratio,
                  width: 22,
                  decoration: BoxDecoration(
                    color: secs > 0 ? KidColors.primary : KidColors.bgDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: secs > 0 ? KidColors.primary : KidColors.borderDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: secs > 0 ? Colors.white : KidColors.textMuted,
                    fontSize: 11,
                    fontWeight: secs > 0 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttentionFunnelSection(List<dynamic> funnel, List<dynamic> categories) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KidColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KidColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: KidColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Audience Attention Funnel',
                style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: KidColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Retention',
                  style: TextStyle(color: KidColors.accent, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Viewing session duration distribution from initial click to deep immersion.',
            style: TextStyle(color: KidColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...funnel.map((stage) {
            final label = stage['label']?.toString() ?? '';
            final count = (stage['count'] as num?)?.toInt() ?? 0;
            final pct = (stage['percentage'] as num?)?.toInt() ?? 0;
            final colorHex = (stage['color_hex'] as num?)?.toInt() ?? 0xFF10B981;
            final barColor = Color(colorHex);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: barColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '$count session${count == 1 ? '' : 's'} ($pct%)',
                        style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: KidColors.bgDark,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

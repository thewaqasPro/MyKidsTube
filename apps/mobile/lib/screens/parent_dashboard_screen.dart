import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../utils/format_utils.dart';
import '../widgets/kid_stat_card.dart';
import 'parent_security_screen.dart';
import 'parent_server_screen.dart';
import 'parent_storage_screen.dart';
import 'parent_media_library_screen.dart';
import 'parent_analytics_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final bool? isUsingDefaultPinOverride;

  const ParentDashboardScreen({
    super.key,
    this.isUsingDefaultPinOverride,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  bool _isUsingDefaultPin = false;

  @override
  void initState() {
    super.initState();
    if (widget.isUsingDefaultPinOverride != null) {
      _isUsingDefaultPin = widget.isUsingDefaultPinOverride!;
    } else {
      _checkDefaultPin();
    }
  }

  Future<void> _checkDefaultPin() async {
    if (widget.isUsingDefaultPinOverride != null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDefault = await provider.isUsingDefaultPin();
    if (mounted) setState(() => _isUsingDefaultPin = isDefault);
  }

  String _formatWatchTime(int seconds) => FormatUtils.formatWatchTime(seconds);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final totalVideos = provider.allVideos.length;
        final downloadedCount = provider.downloadedVideos.length;
        final cachedMb = (provider.cachedBytes / (1024 * 1024)).toStringAsFixed(1);
        final isOnline = provider.isServerOnline;
        final todayTimeStr = _formatWatchTime(provider.todayWatchSeconds);

        return Scaffold(
          backgroundColor: KidColors.bgDark,
          appBar: AppBar(
            title: const Text(
              'Parent Command Center',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            backgroundColor: KidColors.bgDark,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (provider.activeProfile != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: KidColors.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: KidColors.borderDark),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.face_rounded, size: 16, color: KidColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            provider.activeProfile!.name,
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
                ),
              ],
            ],
          ),
          body: _isUsingDefaultPin
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: KidColors.red.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: KidColors.red.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: const Icon(Icons.lock_rounded, color: KidColors.red, size: 56),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Parent Dashboard Locked',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'For child safety, the default PIN (1234) must be changed before accessing parental controls and dashboard settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                  builder: (_) => const ParentSecurityScreen(isForceChange: true),
                                ))
                                .then((_) => _checkDefaultPin());
                          },
                          icon: const Icon(Icons.key_rounded, size: 20),
                          label: const Text(
                            'Set New PIN to Unlock',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KidColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                // Executive Quick Stats (2x2 Grid)
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Catalog Size',
                        value: '$totalVideos Videos',
                        subtitle: '${provider.categories.length} Categories',
                        icon: Icons.video_library_rounded,
                        color: KidColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        title: "Today's Watch",
                        value: todayTimeStr,
                        subtitle: 'Local tracking',
                        icon: Icons.timer_rounded,
                        color: KidColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Offline Media',
                        value: '$cachedMb MB',
                        subtitle: '$downloadedCount downloaded',
                        icon: Icons.storage_rounded,
                        color: KidColors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'VPS Server',
                        value: isOnline ? 'Online' : 'Offline',
                        subtitle: isOnline ? 'Connected' : 'Check URL',
                        icon: Icons.cloud_done_rounded,
                        color: isOnline ? KidColors.green : KidColors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Management Sections',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                // Navigation Tile 1: Media Library & Ingestion
                _buildNavTile(
                  context: context,
                  title: 'Media Library',
                  subtitle: 'Add video URLs, browse catalog, search, and bulk delete',
                  icon: Icons.movie_creation_outlined,
                  accentColor: KidColors.primary,
                  badgeText: '$totalVideos items',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ParentMediaLibraryScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Navigation Tile 2: Local Watch Time & Analytics
                _buildNavTile(
                  context: context,
                  title: 'Watch Time & Analytics',
                  subtitle: 'Local-first screen time stats, top videos, and occasional cloud sync',
                  icon: Icons.insights_rounded,
                  accentColor: KidColors.accent,
                  badgeText: 'Local-First',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ParentAnalyticsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Navigation Tile 3: Device Storage & Offline Media
                _buildNavTile(
                  context: context,
                  title: 'Device Storage & Media',
                  subtitle: 'Manage downloaded videos, free up disk space, single-row actions',
                  icon: Icons.folder_special_outlined,
                  accentColor: KidColors.green,
                  badgeText: '$cachedMb MB',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ParentStorageScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Navigation Tile 4: PIN & Security Settings
                _buildNavTile(
                  context: context,
                  title: 'PIN & Security Settings',
                  subtitle: 'Configure salted parent PIN, protect gate challenge, and locks',
                  icon: Icons.lock_outline_rounded,
                  accentColor: _isUsingDefaultPin ? KidColors.yellow : KidColors.primary,
                  badgeText: _isUsingDefaultPin ? 'Default 1234' : 'Protected',
                  badgeColor: _isUsingDefaultPin ? KidColors.yellow : KidColors.green,
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ParentSecurityScreen()))
                        .then((_) => _checkDefaultPin());
                  },
                ),
                const SizedBox(height: 10),

                // Navigation Tile 5: VPS Server Connection
                _buildNavTile(
                  context: context,
                  title: 'VPS Server Connection',
                  subtitle: 'Configure Cloudflare/VPS base URL, live ping test, device pairing',
                  icon: Icons.dns_outlined,
                  accentColor: isOnline ? KidColors.green : KidColors.red,
                  badgeText: isOnline ? 'Online' : 'Offline',
                  badgeColor: isOnline ? KidColors.green : KidColors.red,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ParentServerScreen()),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Safety Cap Pending Mass Prune Confirmation Alert
                if (provider.hasPendingMassPrune) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF332014),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade700, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Mass Removal Blocked (Safety Cap)',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The server requested deleting ${provider.pendingPruneCount} video(s) (>50% of the local library). This was held to protect offline downloads.',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.orange.shade100,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  await provider.confirmPendingPrune();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Removed pending videos from local library')),
                                    );
                                  }
                                },
                                child: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.orange.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => provider.dismissPendingPrune(),
                                child: const Text('Keep Offline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Footer Quick Actions Toolbar in a Single Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: KidColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KidColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: KidColors.borderDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: provider.isSyncing ? null : () => provider.syncCatalog(),
                          icon: provider.isSyncing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.sync_rounded, color: Colors.white70, size: 18),
                          label: Text(
                            provider.isSyncing ? 'Syncing...' : 'Sync Catalog',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KidColors.surfaceDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.child_care_rounded, size: 18, color: KidColors.yellow),
                          label: const Text('Return to Kids', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return KidStatCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final effectiveBadgeColor = badgeColor ?? accentColor;

    return Container(
      decoration: BoxDecoration(
        color: KidColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KidColors.borderDark, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: effectiveBadgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: effectiveBadgeColor.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: effectiveBadgeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(color: KidColors.textMuted, fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Chevron
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: KidColors.textMuted,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

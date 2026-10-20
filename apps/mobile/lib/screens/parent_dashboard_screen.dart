import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/format_utils.dart';
import 'parent_security_screen.dart';
import 'parent_server_screen.dart';
import 'parent_storage_screen.dart';
import 'parent_media_library_screen.dart';
import 'parent_analytics_screen.dart';
import 'parent_youtube_search_screen.dart';
import '../widgets/add_video_sheet.dart';
import '../widgets/smart_cleanup_sheet.dart';
import '../widgets/app_update_dialog.dart';

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
  int _currentTabIndex = 0;
  final List<int> _tabHistory = [];
  bool _isUsingDefaultPin = false;
  bool _isSyncingFreshVideos = false;

  final List<String> _tabTitles = const [
    'Parent Command Center',
    'Search & Add YouTube Videos',
    'Screen Time & Limits',
    'Parent Settings',
  ];

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

  void _onSelectTab(int index) {
    if (_currentTabIndex == index) return;
    setState(() {
      _tabHistory.add(_currentTabIndex);
      _currentTabIndex = index;
    });
  }

  void _handleBack() {
    if (_isUsingDefaultPin) {
      Navigator.of(context).pop();
      return;
    }
    if (_tabHistory.isNotEmpty) {
      setState(() {
        _currentTabIndex = _tabHistory.removeLast();
      });
    } else if (_currentTabIndex != 0) {
      setState(() {
        _currentTabIndex = 0;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  String _formatWatchTime(int seconds) => FormatUtils.formatWatchTime(seconds);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: _isUsingDefaultPin || (_currentTabIndex == 0 && _tabHistory.isEmpty),
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBack();
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF121212),
            appBar: AppBar(
              title: Text(
                _tabTitles[_currentTabIndex],
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              backgroundColor: const Color(0xFF1A1A1A),
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: _handleBack,
              ),
              actions: [
                if (provider.activeProfile != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF262626),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.face_rounded, size: 16, color: Colors.lightBlueAccent),
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
            ),
            body: _isUsingDefaultPin
                ? _buildLockedScreen()
                : IndexedStack(
                    index: _currentTabIndex,
                    children: [
                      _buildOverviewTab(context, provider),
                      ParentYouTubeSearchScreen(
                        isEmbedded: true,
                        onBack: _handleBack,
                      ),
                      _buildScreenTimeTab(context, provider),
                      _buildSettingsTab(context, provider),
                    ],
                  ),
            bottomNavigationBar: _isUsingDefaultPin
                ? null
                : NavigationBarTheme(
                    data: NavigationBarThemeData(
                      indicatorColor: Colors.redAccent.withValues(alpha: 0.25),
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          );
                        }
                        return const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        );
                      }),
                      iconTheme: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const IconThemeData(color: Colors.redAccent, size: 24);
                        }
                        return const IconThemeData(color: Colors.white54, size: 22);
                      }),
                    ),
                    child: NavigationBar(
                      backgroundColor: const Color(0xFF1A1A1A),
                      selectedIndex: _currentTabIndex,
                      onDestinationSelected: _onSelectTab,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard_rounded),
                          label: 'Overview',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.youtube_searched_for_outlined),
                          selectedIcon: Icon(Icons.youtube_searched_for_rounded),
                          label: 'Search YouTube',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.timer_outlined),
                          selectedIcon: Icon(Icons.timer_rounded),
                          label: 'Screen Time',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings_rounded),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 0: Clean Android Standard Overview & Controls
  // -------------------------------------------------------------
  Widget _buildOverviewTab(BuildContext context, AppProvider provider) {
    final totalVideos = provider.allVideos.length;
    final downloadedCount = provider.downloadedVideos.length;
    final cachedMb = (provider.cachedBytes / (1024 * 1024)).toStringAsFixed(1);
    final isOnline = provider.isServerOnline;
    final todayTimeStr = _formatWatchTime(provider.todayWatchSeconds);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Safety Cap Mass Removal Alert (if pending prune)
          if (provider.hasPendingMassPrune) ...[
            _buildMassPruneCard(context, provider),
            const SizedBox(height: 14),
          ],

          // Executive Summary Stats (Clean Android Cards)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: '${provider.categories.length} Categories',
                  value: '$totalVideos / ${provider.catalogLimit}',
                  title: 'Catalog Size',
                  icon: Icons.video_library_rounded,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Local tracking',
                  value: todayTimeStr,
                  title: "Today's Watch",
                  icon: Icons.timer_rounded,
                  color: Colors.lightBlueAccent,
                ),
              ),
            ],
          ),

          // Near-limit warning banner (at >= 180 of 200 videos)
          if (provider.isCatalogNearLimit) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catalog near capacity (${provider.allVideos.length}/${provider.catalogLimit}). Auto-rotation will recycle least-watched videos or run Smart Cleanup below.',
                      style: const TextStyle(color: Colors.amber, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Fresh Video Rotation Card
          Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.autorenew_rounded, color: Colors.cyanAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Fresh Video Rotation',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Text(
                        '${provider.followedChannels.length} followed channels',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Rotates new kid videos from followed channels and retires unwatched videos under the 200-video cap.',
                    style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSyncingFreshVideos
                              ? null
                              : () async {
                                  setState(() => _isSyncingFreshVideos = true);
                                  try {
                                    final summary = await provider.syncAndRotateCatalog();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            summary.addedCount > 0
                                                ? 'Added ${summary.addedCount} fresh videos from followed channels!'
                                                : 'Catalog is already fresh and up to date.',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isSyncingFreshVideos = false);
                                  }
                                },
                          icon: _isSyncingFreshVideos
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Get Fresh Videos', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C2C2C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const SmartCleanupSheet(),
                            );
                          },
                          icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: Colors.amber),
                          label: const Text('Smart Cleanup', style: TextStyle(fontSize: 12, color: Colors.amber)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.amber.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // HERO ACTION: Search YouTube & Channel Videos (Switches to Tab 1)
          Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _onSelectTab(1);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.youtube_searched_for_rounded, color: Colors.redAccent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Search YouTube & Channels',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Badge(
                                label: Text('New', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.redAccent,
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Search by channel name (e.g. @peppapig) or topic. 1-tap add videos to child catalog.',
                            style: TextStyle(color: Colors.white60, fontSize: 12.5, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white38),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Primary Direct Action: Add YouTube Video (Paste URL)
          _buildSettingsCard(
            title: 'Add YouTube Video',
            subtitle: 'Paste YouTube video, short, or playlist to add to kids feed',
            icon: Icons.add_circle_outline_rounded,
            iconColor: Colors.redAccent,
            badge: 'Instant',
            onTap: () => AddVideoSheet.show(context),
          ),

          const SizedBox(height: 18),

          const Text(
            'Content & Safety',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          // Media Library
          _buildSettingsCard(
            title: 'Media Library',
            subtitle: 'Browse, search, and delete curated videos',
            icon: Icons.movie_creation_outlined,
            iconColor: Colors.redAccent,
            badge: '$totalVideos items',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParentMediaLibraryScreen()),
              );
            },
          ),

          const SizedBox(height: 10),

          // Watch Time & Analytics
          _buildSettingsCard(
            title: 'Watch Time & Analytics',
            subtitle: 'Screen time stats, top videos, and watch history',
            icon: Icons.insights_rounded,
            iconColor: Colors.lightBlueAccent,
            badge: 'Local-First',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParentAnalyticsScreen()),
              );
            },
          ),

          const SizedBox(height: 10),

          // PIN & Security Settings
          _buildSettingsCard(
            title: 'PIN & Security Settings',
            subtitle: 'Configure parent PIN, protect gate challenge, and locks',
            icon: Icons.lock_outline_rounded,
            iconColor: _isUsingDefaultPin ? Colors.amberAccent : Colors.greenAccent,
            badge: _isUsingDefaultPin ? 'Default 1234' : 'Protected',
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ParentSecurityScreen()))
                  .then((_) => _checkDefaultPin());
            },
          ),

          const SizedBox(height: 10),

          // Curated Starter Pack
          _buildSettingsCard(
            title: 'Curated Starter Pack',
            subtitle: 'Load or restore 60 initial kid-safe videos (30 videos & 30 shorts)',
            icon: Icons.auto_awesome_rounded,
            iconColor: Colors.amberAccent,
            badge: '60 Videos',
            onTap: () => _showStarterPackDialog(context, provider),
          ),

          const SizedBox(height: 20),

          // Autoplay & Viewing Limits Header
          const Text(
            'Autoplay & Viewing Limits',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          // Autoplay settings card with exact test labels
          _buildAutoplaySettingsCard(context, provider),

          const SizedBox(height: 20),

          // Intro & Promotion Skipping Header
          const Text(
            'Intro & Promotion Skipping',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          _buildIntroSkipSettingsCard(context, provider),

          const SizedBox(height: 20),

          const Text(
            'Advanced Options (Optional)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          // VPS Server Connection
          _buildSettingsCard(
            title: 'VPS Server Connection',
            subtitle: 'Optional: connect a private self-hosted Nginx or Cloudflare backend',
            icon: Icons.dns_outlined,
            iconColor: isOnline ? Colors.greenAccent : Colors.white38,
            badge: isOnline ? 'Online' : 'Optional',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParentServerScreen()),
              );
            },
          ),

          const SizedBox(height: 10),

          // Device Storage & Media
          _buildSettingsCard(
            title: 'Device Storage & Media',
            subtitle: 'Manage downloaded offline cache ($downloadedCount files) and free up disk space',
            icon: Icons.folder_special_outlined,
            iconColor: Colors.tealAccent,
            badge: '$cachedMb MB',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParentStorageScreen()),
              );
            },
          ),

          const SizedBox(height: 10),

          // App Updates & Version Card
          _buildAppUpdateCard(context, provider),

          const SizedBox(height: 20),

          // Return to Kids Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF222222),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.child_care_rounded, size: 20, color: Colors.amberAccent),
              label: const Text('Return to Kids', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: Screen Time & Limits
  // -------------------------------------------------------------
  Widget _buildScreenTimeTab(BuildContext context, AppProvider provider) {
    final todayWatchStr = _formatWatchTime(provider.todayWatchSeconds);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Today's Watch Time Card
          Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time_filled_rounded, color: Colors.blueAccent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Screen Time",
                          style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todayWatchStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightBlueAccent,
                      side: const BorderSide(color: Colors.lightBlueAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ParentAnalyticsScreen()),
                      );
                    },
                    icon: const Icon(Icons.insights_rounded, size: 16),
                    label: const Text('Analytics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildAutoplaySettingsCard(context, provider),

          const SizedBox(height: 16),

          _buildIntroSkipSettingsCard(context, provider),

          const SizedBox(height: 16),

          _buildSettingsCard(
            title: 'Detailed Watch Analytics',
            subtitle: 'Inspect daily charts, most-watched videos, and session history',
            icon: Icons.bar_chart_rounded,
            iconColor: Colors.purpleAccent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParentAnalyticsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: Settings & Device
  // -------------------------------------------------------------
  Widget _buildSettingsTab(BuildContext context, AppProvider provider) {
    final cachedMb = (provider.cachedBytes / (1024 * 1024)).toStringAsFixed(1);
    final isOnline = provider.isServerOnline;
    final downloadedCount = provider.downloadedVideos.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro & Promotion Skipping Settings Card
          _buildIntroSkipSettingsCard(context, provider),

          const SizedBox(height: 12),

          // Security PIN Settings
          _buildSettingsCard(
            title: 'PIN & Security Settings',
            subtitle: 'Change 4-digit PIN, protect gate challenge, and locks',
            icon: Icons.lock_outline_rounded,
            iconColor: _isUsingDefaultPin ? Colors.amberAccent : Colors.greenAccent,
            badge: _isUsingDefaultPin ? 'Default 1234' : 'Protected',
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ParentSecurityScreen()))
                  .then((_) => _checkDefaultPin());
            },
          ),

          const SizedBox(height: 12),

          // Device Storage & Media
          _buildSettingsCard(
            title: 'Device Storage & Media',
            subtitle: 'Manage downloaded offline cache ($downloadedCount files) and free up disk space',
            icon: Icons.folder_special_outlined,
            iconColor: Colors.tealAccent,
            badge: '$cachedMb MB',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParentStorageScreen()),
              );
            },
          ),

          const SizedBox(height: 12),

          // VPS Server Connection
          _buildSettingsCard(
            title: 'VPS Server Connection',
            subtitle: 'Optional: connect a private self-hosted Nginx backend',
            icon: Icons.dns_outlined,
            iconColor: isOnline ? Colors.greenAccent : Colors.white38,
            badge: isOnline ? 'Online' : 'Optional',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParentServerScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // About MyKidsTube Footer
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.child_care_rounded, color: Colors.white54, size: 28),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MyKidsTube v1.3.0',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Distraction-free, zero-ad open-source player\nLicensed under the MIT License',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // REUSABLE CARDS & TILES
  // -------------------------------------------------------------
  Widget _buildMetricTile({
    required String title,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoplaySettingsCard(BuildContext context, AppProvider provider) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.redAccent,
              title: const Text(
                'Autoplay Next Video',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Automatically play the next video when playback ends',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: provider.autoplayEnabled,
              onChanged: (val) => provider.setAutoplayEnabled(val),
            ),
            const Divider(color: Colors.white10, height: 16),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Watch Limit',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Stop playback when session limit is reached',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                DropdownButton<int>(
                  value: provider.autoplaySessionLimitMinutes,
                  dropdownColor: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(10),
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Unlimited')),
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 45, child: Text('45 min')),
                    DropdownMenuItem(value: 60, child: Text('60 min (Default)')),
                    DropdownMenuItem(value: 90, child: Text('90 min')),
                    DropdownMenuItem(value: 120, child: Text('120 min')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await provider.setAutoplaySessionLimitMinutes(val);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSkipSettingsCard(BuildContext context, AppProvider provider) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fast_forward_rounded, color: Colors.amberAccent, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skip Channel & Branding Intros',
                        style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Skip repetitive opening promotions and brand jingles',
                        style: TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.amberAccent,
              title: const Text(
                'Skip Intro on Long Videos',
                style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Skip opening seconds on standard horizontal videos (Enabled by default)',
                style: TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
              value: provider.skipIntroLongVideos,
              onChanged: (val) => provider.setSkipIntroLongVideos(val),
            ),
            const Divider(color: Colors.white10, height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.amberAccent,
              title: const Text(
                'Skip Intro on Shorts',
                style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Skip opening seconds on vertical shorts (Disabled by default)',
                style: TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
              value: provider.skipIntroShorts,
              onChanged: (val) => provider.setSkipIntroShorts(val),
            ),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Intro Skip Duration',
                        style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Number of seconds to skip at start of each video',
                        style: TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                DropdownButton<int>(
                  value: provider.skipIntroSeconds,
                  dropdownColor: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(10),
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 seconds')),
                    DropdownMenuItem(value: 5, child: Text('5 seconds (Default)')),
                    DropdownMenuItem(value: 6, child: Text('6 seconds')),
                    DropdownMenuItem(value: 8, child: Text('8 seconds')),
                    DropdownMenuItem(value: 10, child: Text('10 seconds')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await provider.setSkipIntroSeconds(val);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUpdateCard(BuildContext context, AppProvider provider) {
    final update = provider.availableUpdate;
    final isChecking = provider.isCheckingForUpdate;
    final hasUpdate = update?.hasUpdate ?? false;

    String badgeText;
    if (isChecking) {
      badgeText = 'Checking...';
    } else if (hasUpdate) {
      badgeText = 'v${update!.latestVersion} Available!';
    } else {
      badgeText = 'Check Updates';
    }

    return _buildSettingsCard(
      title: 'Check for App Updates',
      subtitle: hasUpdate
          ? 'New version v${update!.latestVersion} is ready to download and install'
          : 'Verify against GitHub releases and install the latest update',
      icon: Icons.system_update_rounded,
      iconColor: hasUpdate ? Colors.amberAccent : Colors.tealAccent,
      badge: badgeText,
      onTap: () async {
        final info = await provider.checkForUpdate(manual: true);
        if (!context.mounted) return;
        if (info != null) {
          if (info.hasUpdate) {
            AppUpdateDialog.show(context, info: info);
          } else if (info.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(info.errorMessage ?? 'Failed to check for updates'),
                backgroundColor: Colors.redAccent,
              ),
            );
          } else {
            AppUpdateDialog.show(context, info: info);
          }
        }
      },
    );
  }

  Widget _buildMassPruneCard(BuildContext context, AppProvider provider) {
    return Container(
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The server requested deleting ${provider.pendingPruneCount} video(s). This was held to protect offline downloads.',
            style: TextStyle(color: Colors.orange.shade100, fontSize: 12.5),
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
    );
  }

  Widget _buildLockedScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              'Parent Dashboard Locked',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
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
              label: const Text('Set New PIN to Unlock', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStarterPackDialog(BuildContext context, AppProvider provider) {
    bool restoreDeleted = false;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Curated Starter Pack',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Load 60 curated kid-safe videos & shorts into your library:',
                      style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: Colors.greenAccent),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('30 Long-Form Videos (Cartoons, Songs, Learning)', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: Colors.greenAccent),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('30 Authentic 9:16 Vertical Shorts & Reels', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: Colors.greenAccent),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Preserves existing custom videos', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.redAccent,
                      title: const Text(
                        'Restore previously deleted starter videos',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Unmarks videos you may have removed earlier',
                        style: TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                      value: restoreDeleted,
                      onChanged: (val) {
                        setDialogState(() {
                          restoreDeleted = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    final count = await provider.loadStarterCatalog(resetTombstones: restoreDeleted);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully loaded $count starter videos!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Load Starter Pack', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

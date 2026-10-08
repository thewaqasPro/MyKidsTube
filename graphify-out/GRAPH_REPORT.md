# Graph Report - MyKidsTube  (2026-10-08)

## Corpus Check
- 245 files · ~114,575 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1248 nodes · 2191 edges · 77 communities (53 shown, 18 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 10 edges (avg confidence: 0.89)
- Token cost: 99,985 input · 3,507 output

## Community Hubs (Navigation)
- Portal Upload & Studio Analytics
- Viewing Analytics & Metrics
- Viewing Analytics & Metrics
- Offline Media Download Service
- Kid Player & Orientation Layouts
- Vertical Shorts Feed Screen
- Viewing Analytics & Metrics
- UI Design Tokens & Constants
- Video Upload & Ingestion
- Mobile App State Provider
- Offline Media Download Service
- Portal Web Streaming Pages
- Offline Media Download Service
- Offline Media Download Service
- YouTube Sandboxed Embed Player
- Navigation Sidebar Component
- Mobile App State Provider
- Category Filter Navigation
- Multi Command Runner Module
- Child Profiles & Avatars
- Child Profiles & Avatars
- Device Pairing Screen Module
- Viewing Analytics & Metrics
- Video Upload & Ingestion
- Portal Web Streaming Pages
- Parent Security Screen Module
- Touch Lock Overlay Module
- Parent Gate Dialog Module
- Viewing Analytics & Metrics
- Astro Config Module
- Viewing Analytics & Metrics
- Cross Platform Paths Module
- Appdelegate Module
- Json Patterns Module
- Kid Player & Orientation Layouts
- Better-Auth Passkeys & Sessions
- Index Module
- File System Context Module
- VPS API Client Networking
- Mobile App State Provider
- Package Module
- Better-Auth Passkeys & Sessions
- UI Design Tokens & Constants
- Viewing Analytics & Metrics
- Tsconfig Module
- Drizzle Database ORM Schema
- Cleanup Service Module
- Category Item Module
- Child Profiles & Avatars
- Ambient Blur Background Module
- Drizzle Database ORM Schema
- Video Upload & Ingestion
- Index Module
- Local SQLite Storage Service
- Mainactivity Module
- Drizzle Database ORM Schema
- Pnpm Workspace Module
- Viewing Analytics & Metrics
- VPS API Client Networking
- Readme Module
- Package Module
- Build Apk Module
- Dev Server Module
- Make Dev Cert Module
- Run Mobile Module
- Icon App 1024X1024@1X Module
- Icon App 20X20@1X Module
- Agents Module
- Claude Module
- Favicon Module
- Better-Auth Passkeys & Sessions

## God Nodes (most connected - your core abstractions)
1. `AppProvider` - 56 edges
2. `getCorsHeaders()` - 42 edges
3. `react` - 41 edges
4. `handleOptions()` - 38 edges
5. `lucide-react` - 35 edges
6. `Video` - 34 edges
7. `getDatabase()` - 29 edges
8. `astro` - 28 edges
9. `requireParent()` - 28 edges
10. `ChildProfile` - 21 edges

## Surprising Connections (you probably didn't know these)
- `Astro Starter Kit: Minimal README` --conceptually_related_to--> `AI Engineering Workflow & Change Log`  [INFERRED]
  apps/portal/README.md → docs/ai-workflow.md
- `initState` --references--> `AppProvider`  [EXTRACTED]
  apps/mobile/lib/main.dart → apps/mobile/lib/providers/app_provider.dart
- `_initPairing` --references--> `AppProvider`  [EXTRACTED]
  apps/mobile/lib/screens/device_pairing_screen.dart → apps/mobile/lib/providers/app_provider.dart
- `_scheduleNextPoll` --references--> `AppProvider`  [EXTRACTED]
  apps/mobile/lib/screens/device_pairing_screen.dart → apps/mobile/lib/providers/app_provider.dart
- `build` --references--> `AppProvider`  [EXTRACTED]
  apps/mobile/lib/screens/parent_analytics_screen.dart → apps/mobile/lib/providers/app_provider.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **MyKidsTube System Architecture** — apps_mobile_lib, apps_server_backend, apps_server_nginx [EXTRACTED 1.00]
- **Project Documentation** — readme_md, design_md, docs_architecture, docs_api_reference, docs_multi_user_pairing, docs_monorepo_structure_plan [EXTRACTED 1.00]
- **KidsTube Monorepo Structure** — apps_portal_readme, apps_server_readme, docs_monorepo_structure_plan [EXTRACTED 1.00]
- **KidsTube Deployment & Infrastructure** — apps_server_docker_compose, docs_vps_optimization_1gb, apps_portal_readme [INFERRED 0.90]

## Communities (77 total, 18 thin omitted)

### Community 0 - "Portal Upload & Studio Analytics"
Cohesion: 0.05
Nodes (79): UploadPage(), AnalyticsService, getCorsHeaders(), handleOptions(), fetchYoutubeOembed, getDatabase(), getDbData(), getPendingVideos() (+71 more)

### Community 1 - "Viewing Analytics & Metrics"
Cohesion: 0.05
Nodes (45): AppEnv, getAppEnv(), DrizzleDb, getDrizzle(), getDrizzleDb(), watchEvents, account, passkey (+37 more)

### Community 2 - "Viewing Analytics & Metrics"
Cohesion: 0.03
Nodes (66): AppOrientationMode get, _activeProfile, addLocalProfile, _allVideos, _api, applyCurrentOrientationMode, _applyOrientationMode, _availableProfiles (+58 more)

### Community 3 - "Offline Media Download Service"
Cohesion: 0.05
Nodes (45): KidsTubeSplashScreen, VideoItem, ProfileSelectorDialog, AmbientBlurBackground, ChildAvatar, KidProfileSwitcherSheet, autoAdvance, build (+37 more)

### Community 4 - "Kid Player & Orientation Layouts"
Cohesion: 0.05
Nodes (43): _accumulatedSessionSeconds, _buildFixedTopBar, _buildLandscapeControls, _buildLandscapeFullscreen, _buildLandscapeVideoCard, _buildPendingOrErrorState, _buildPillButton, _buildRedScrubber (+35 more)

### Community 5 - "Vertical Shorts Feed Screen"
Cohesion: 0.05
Nodes (37): _accumulatedSessionSeconds, _autoAdvance, build, _buildShortPendingState, _controllerGeneration, _controllers, _createController, createState (+29 more)

### Community 6 - "Viewing Analytics & Metrics"
Cohesion: 0.05
Nodes (37): batchUpsertCatalog, clearAllCache, clearDownloadedStatus, clearStaleCatalogCache, clearWatchHistory, _createDB, _database, DatabaseService (+29 more)

### Community 7 - "UI Design Tokens & Constants"
Cohesion: 0.06
Nodes (33): accent, bgDark, borderDark, borderSubtle, bubblegum, canvasDark, cardDark, cardElevated (+25 more)

### Community 8 - "Video Upload & Ingestion"
Cohesion: 0.15
Nodes (21): CATEGORY_META, CategoryMeta, CategoryPills(), CategoryPillsProps, KidsPortalProps, ChannelItem, KidsSidebar(), KidsSidebarProps (+13 more)

### Community 9 - "Mobile App State Provider"
Cohesion: 0.09
Nodes (28): AppProvider, build, _buildLandscapeSplitPlayer, _buildPortraitInlinePlayer, didChangeDependencies, initState, _playNextVideo, _playPreviousVideo (+20 more)

### Community 10 - "Offline Media Download Service"
Cohesion: 0.07
Nodes (28): build, _buildCategoryPills, _buildEmptyState, _buildResponsiveFeed, _buildShortsShelf, _buildYouTubeAppBar, _CategoryFilterItem, createState (+20 more)

### Community 11 - "Portal Web Streaming Pages"
Cohesion: 0.15
Nodes (20): KidsPortal(), ShortsPage(), WatchPage(), ShortsActionPills(), ShortsActionPillsProps, ShortsReel(), ShortsReelProps, WatchUpNextSidebar() (+12 more)

### Community 12 - "Offline Media Download Service"
Cohesion: 0.07
Nodes (27): _activeDownloads, cancelDownload, cleanupOrphanFiles, deleteAllDownloadedMedia, deleteDownloadedFile, _dio, DownloadProgressCallback, _downloadQueue (+19 more)

### Community 13 - "Offline Media Download Service"
Cohesion: 0.07
Nodes (26): categoryId, channelIconUrl, channelName, copyWith, downloadProgress, DownloadStatus, duration, durationFormatted (+18 more)

### Community 14 - "YouTube Sandboxed Embed Player"
Cohesion: 0.08
Nodes (25): , aspectRatio, autoPlay, build, _controller, createState, didUpdateWidget, dispose (+17 more)

### Community 15 - "Navigation Sidebar Component"
Cohesion: 0.12
Nodes (18): BulkDeleteProgressItem, BulkDeleteProgressModal(), BulkDeleteProgressModalProps, DeleteConfirmModal(), DeleteConfirmModalProps, StudioDashboard(), StudioSidebar(), StudioSidebarProps (+10 more)

### Community 16 - "Mobile App State Provider"
Cohesion: 0.09
Nodes (21): AppOrientationMode, build, _buildMetricMiniCard, createState, _handleClearStorage, _handleDownloadAll, _handleResetCache, _isClearing (+13 more)

### Community 17 - "Category Filter Navigation"
Cohesion: 0.10
Nodes (21): build, _buildCategoryPill, _buildVideoRowItem, _confirmDeleteVideos, createState, dispose, _filterCategory, initState (+13 more)

### Community 18 - "Multi Command Runner Module"
Cohesion: 0.11
Nodes (19): description, main, name, ProcessCommand, run, runCommand, runner, ToolCommandRunner (+11 more)

### Community 19 - "Child Profiles & Avatars"
Cohesion: 0.12
Nodes (17): build, _buildAgeChip, _promptAddProfile, show, _showCreateProfileDialog, main, main, main (+9 more)

### Community 20 - "Child Profiles & Avatars"
Cohesion: 0.10
Nodes (19): _authOptions, _authToken, checkDeviceStatus, checkHealth, deleteVideos, _dio, fetchCatalog, fetchProfiles (+11 more)

### Community 21 - "Device Pairing Screen Module"
Cohesion: 0.12
Nodes (17): build, createState, DevicePairingScreen, _DevicePairingScreenState, dispose, _initPairing, initState, _isExpired (+9 more)

### Community 22 - "Viewing Analytics & Metrics"
Cohesion: 0.12
Nodes (17): _analytics, build, _buildAttentionFunnelSection, _buildFilterChip, _buildMetricTile, _buildProfileFilterSelector, _buildWeeklyChart, createState (+9 more)

### Community 23 - "Video Upload & Ingestion"
Cohesion: 0.16
Nodes (11): LoginPage(), LoginPageProps, MasterAccountAuthCard(), MasterAccountAuthCardProps, QuickPinKeypadCard(), QuickPinKeypadCardProps, UploadBatchHelperCard(), UploadBatchHelperCardProps (+3 more)

### Community 24 - "Portal Web Streaming Pages"
Cohesion: 0.16
Nodes (14): ShortsPageProps, StudioDashboardProps, VideoCard(), VideoCardProps, VideoGrid(), VideoGridProps, WatchPageProps, WatchDetails() (+6 more)

### Community 25 - "Parent Security Screen Module"
Cohesion: 0.12
Nodes (16): build, _changePin, _confirmPinController, createState, _currentPinController, dispose, initState, _isSaving (+8 more)

### Community 26 - "Touch Lock Overlay Module"
Cohesion: 0.13
Nodes (15): AnimationController, build, createState, dispose, initState, isLocked, _onHoldEnd, _onHoldStart (+7 more)

### Community 27 - "Parent Gate Dialog Module"
Cohesion: 0.13
Nodes (15): _answerController, build, createState, dispose, _errorMessage, _expectedAnswer, initState, _num1 (+7 more)

### Community 28 - "Viewing Analytics & Metrics"
Cohesion: 0.14
Nodes (14): _buildNavTile, _buildSummaryCard, _checkDefaultPin, createState, _formatWatchTime, initState, _isUsingDefaultPin, ParentDashboardScreen (+6 more)

### Community 29 - "Astro Config Module"
Cohesion: 0.15
Nodes (13): name, type, version, @astrojs/cloudflare, @astrojs/react, @libsql/client, react-dom, tailwindcss (+5 more)

### Community 30 - "Viewing Analytics & Metrics"
Cohesion: 0.16
Nodes (11): StudioAnalyticsView(), StudioAnalyticsViewProps, AnalyticsKpiGrid(), AnalyticsKpiGridProps, AnalyticsRetentionFunnel(), AnalyticsRetentionFunnelProps, CategoryShareItem, FunnelItem (+3 more)

### Community 31 - "Cross Platform Paths Module"
Cohesion: 0.14
Nodes (13): compoundExt, computeWebAssetKey, contains, ext, insertContentHash, isCanvasKitWasmAsset, main, nativeSamplePath (+5 more)

### Community 32 - "Appdelegate Module"
Cohesion: 0.16
Nodes (10): Any, AppDelegate, RunnerTests, Bool, Flutter, FlutterAppDelegate, UIApplication, UIKit (+2 more)

### Community 33 - "Json Patterns Module"
Cohesion: 0.18
Nodes (12): ApiResponse, code, data, error, ErrorResponse, main, message, parseApiResponse (+4 more)

### Community 34 - "Kid Player & Orientation Layouts"
Cohesion: 0.21
Nodes (13): KidHomeScreen, _KidHomeScreenState, KidPlayerScreen, _KidPlayerScreenState, KidShortsFeedScreen, _KidShortsFeedScreenState, ParentStorageScreen, _ParentStorageScreenState (+5 more)

### Community 35 - "Better-Auth Passkeys & Sessions"
Cohesion: 0.15
Nodes (13): dependencies, astro, @astrojs/cloudflare, @astrojs/react, better-auth, @better-auth/drizzle-adapter, @better-auth/passkey, drizzle-orm (+5 more)

### Community 36 - "Index Module"
Cohesion: 0.22
Nodes (6): AppError, BadRequestError, ConflictError, ForbiddenError, NotFoundError, UnauthorizedError

### Community 37 - "File System Context Module"
Cohesion: 0.17
Nodes (11): dir, fs, listSubdirectoryNames, main, pathContext, projectDir, subdirs, Directory (+3 more)

### Community 38 - "VPS API Client Networking"
Cohesion: 0.21
Nodes (3): Android Launcher Icon, KidsTube Documentation Index, VPS Optimization Guide

### Community 39 - "Mobile App State Provider"
Cohesion: 0.18
Nodes (11): appProvider, build, createState, _hasStartedInit, initState, KidsTubeApp, _KidsTubeAppState, main (+3 more)

### Community 40 - "Package Module"
Cohesion: 0.17
Nodes (12): scripts, astro, build, db:migrate:local, db:migrate:remote, db:sync:remote, deploy, dev (+4 more)

### Community 41 - "Better-Auth Passkeys & Sessions"
Cohesion: 0.21
Nodes (8): SecurityPasskeysCard(), SecurityPasskeysCardProps, SecurityPinGateCard(), SecurityPinGateCardProps, SecuritySessionsCard(), SecuritySessionsCardProps, StudioSecurityTab(), StudioSecurityTabProps

### Community 42 - "UI Design Tokens & Constants"
Cohesion: 0.18
Nodes (10): _AvatarConfig, avatarIcon, build, _getAvatarConfig, gradientColors, icon, radius, showBorder (+2 more)

### Community 43 - "Viewing Analytics & Metrics"
Cohesion: 0.24
Nodes (8): ShortCard(), ShortsShelf(), ShortsShelfProps, AnalyticsLeaderboardTables(), AnalyticsLeaderboardTablesProps, LovedVideoItem, SkippedVideoItem, getThumbnailUrl()

### Community 44 - "Tsconfig Module"
Cohesion: 0.20
Nodes (9): compilerOptions, jsx, jsxImportSource, paths, types, exclude, extends, include (+1 more)

### Community 45 - "Drizzle Database ORM Schema"
Cohesion: 0.22
Nodes (8): account_id, compatibility_date, compatibility_flags, d1_databases, name, r2_buckets, $schema, workers_dev

### Community 47 - "Category Item Module"
Cohesion: 0.25
Nodes (7): CategoryItem, displayOrder, fromMap, icon, id, name, toMap

### Community 48 - "Child Profiles & Avatars"
Cohesion: 0.25
Nodes (7): ageBracket, avatarIcon, ChildProfile, fromMap, id, name, toMap

### Community 49 - "Ambient Blur Background Module"
Cohesion: 0.25
Nodes (7): build, controller, fallbackThumbnailUrl, dart:ui, package:video_player/video_player.dart, String?, VideoPlayerController?

### Community 50 - "Drizzle Database ORM Schema"
Cohesion: 0.25
Nodes (8): devDependencies, @cloudflare/workers-types, drizzle-kit, @libsql/client, @types/node, @types/react, @types/react-dom, typescript

### Community 51 - "Video Upload & Ingestion"
Cohesion: 0.57
Nodes (6): command_download(), command_export(), command_prune(), command_status(), command_upload(), sync-mykidstube.sh script

### Community 53 - "Local SQLite Storage Service"
Cohesion: 0.50
Nodes (3): d1Dir, localDbPath, sqliteFiles

### Community 56 - "Pnpm Workspace Module"
Cohesion: 0.67
Nodes (3): Portal PNPM Workspace Config, Astro Starter Kit: Minimal README, AI Engineering Workflow & Change Log

## Knowledge Gaps
- **623 isolated node(s):** `runner`, `name`, `description`, `main`, `runCommand` (+618 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 723 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **18 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppProvider` connect `Mobile App State Provider` to `Viewing Analytics & Metrics`, `Kid Player & Orientation Layouts`, `Kid Player & Orientation Layouts`, `Vertical Shorts Feed Screen`, `Mobile App State Provider`, `Offline Media Download Service`, `Mobile App State Provider`, `Category Filter Navigation`, `Child Profiles & Avatars`, `Device Pairing Screen Module`, `Viewing Analytics & Metrics`, `Parent Security Screen Module`, `Parent Gate Dialog Module`, `Viewing Analytics & Metrics`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **Why does `astro` connect `Portal Upload & Studio Analytics` to `Viewing Analytics & Metrics`, `Astro Config Module`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `react` connect `Video Upload & Ingestion` to `Video Upload & Ingestion`, `Better-Auth Passkeys & Sessions`, `Viewing Analytics & Metrics`, `Portal Web Streaming Pages`, `Navigation Sidebar Component`, `Portal Web Streaming Pages`, `Astro Config Module`, `Viewing Analytics & Metrics`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `runner`, `name`, `description` to the rest of the system?**
  _623 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Portal Upload & Studio Analytics` be split into smaller, more focused modules?**
  _Cohesion score 0.05192761605035405 - nodes in this community are weakly interconnected._
- **Should `Viewing Analytics & Metrics` be split into smaller, more focused modules?**
  _Cohesion score 0.05063291139240506 - nodes in this community are weakly interconnected._
- **Should `Viewing Analytics & Metrics` be split into smaller, more focused modules?**
  _Cohesion score 0.029850746268656716 - nodes in this community are weakly interconnected._
# Video Rotation Algorithm, Auto-Refresh & 200-Video Catalog Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix video playback repetition in the recommendation/queue algorithm, implement automated YouTube channel video rotation to retire disliked/stale videos, and enforce a strict 200-video catalog cap with smart cleanup and parent controls.

**Architecture:** 
1. Replace random queue sampling with a **Non-Repeating Cycle Deck (Fisher-Yates cycle)** in `InfiniteVideoQueue` ensuring 100% catalog coverage before any single video repeats.
2. Build an **Engagement & Stale Detection Engine** (`EngagementScoreService`) that calculates video fatigue, completion rate, and skip counts to safely identify disliked videos.
3. Introduce **Followed Channels & Automated Fresh Video Ingestion** (`CatalogRotatorService`) backed by SQLite table `followed_channels` to fetch fresh uploads from parents' selected channels.
4. Implement a **200-Video Catalog Cap & Smart Pruning Engine** with auto-rotation safeguards (protecting favorites, downloads, and pinned videos) and Parent Dashboard UI controls.

**Tech Stack:** Dart, Flutter, SQLite (`sqflite`), Provider, `youtube_explode_dart`.

**Spec:** Requirements articulated in User Request:
- Fix algorithm repetition (currently repeats 6–10 videos out of 100).
- Automatically rotate and refresh new videos from YouTube channels while retiring old/unliked videos.
- Support manual and automated "Get Fresh Videos" / channel resync.
- Strictly cap catalog at maximum ~200 videos, notifying parents and offering automatic/manual pruning of unnecessary videos.

---

## Global Constraints

- **Non-destructive Protection:** Favorites (`favoriteVideoIds`) and downloaded offline media (`download_status == downloaded`) must **NEVER** be automatically pruned or deleted.
- **Tombstone Integrity:** Any video manually deleted by a parent must stay recorded in `deleted_videos` table to ensure automated rotation never resurrects previously deleted content.
- **Hard Catalog Cap:** Total active video items in SQLite should not exceed 200.
- **Offline Reliability:** Auto-rotation only triggers when internet connectivity is active; failures fail gracefully without disrupting the existing offline library.
- **Dart & Flutter Standards:** Adhere to Dart 3.6+ idioms, Provider reactive state management, and existing test coverage.

---

## Review Focus

1. **Cycle Queue Exhaustion:** When a pool of 100 videos is queued, does the queue guarantee that all 100 videos appear before any video repeats?
2. **Safety Guard on Auto-Prune:** Does the pruning engine strictly preserve favorites and downloaded videos, even when the 200 cap is exceeded?
3. **Resurrection Prevention:** If a parent previously deleted a video from YouTube channel X, does "Get Fresh Videos" skip that video ID?
4. **Network Resilience:** If `youtube_explode_dart` throttles or channel fetch fails during background rotation, does the app preserve the existing catalog without error dialogs?
5. **Zero-Watch vs Active Skip Differentiation:** Does the engagement score distinguish between a brand new video (which deserves novelty) and an old video skipped within 5 seconds?

---

### Task 1: Non-Repeating Fisher-Yates Cycle Queue in `InfiniteVideoQueue`

**Files:**
- Modify: `apps/mobile/lib/services/infinite_video_queue.dart:1-125`
- Test: `apps/mobile/test/infinite_video_queue_test.dart`

**Interfaces:**
- Consumes: `VideoItem` from `apps/mobile/lib/models/video_item.dart`
- Produces: `InfiniteVideoQueue` with guaranteed full-pool exhaustion cycle and category balancing.

- [ ] **Step 1: Write the failing test for 100-video cycle coverage**

In `apps/mobile/test/infinite_video_queue_test.dart`:
```dart
test('InfiniteVideoQueue guarantees all pool items are played before repeating when pool has 100 videos', () {
  final pool = List.generate(100, (i) => VideoItem(
    id: 'vid_$i',
    youtubeId: 'vid_$i',
    title: 'Video $i',
    categoryId: i < 50 ? 'cartoons' : 'learning',
    sourceUrl: 'https://youtube.com/watch?v=vid_$i',
    thumbnailUrl: 'https://img.com/$i.jpg',
  ));

  final queue = InfiniteVideoQueue(pool: pool);
  queue.ensureCapacity(0, threshold: 1, batchSize: 100);

  // Check the first 100 items generated (including initial)
  final first100 = queue.items.take(100).map((v) => v.id).toList();
  final uniqueCount = first100.toSet().length;

  // Expect all 100 unique videos before any video appears a second time
  expect(uniqueCount, equals(100));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/infinite_video_queue_test.dart`
Expected: FAIL (currently repeats only ~10 videos due to `half.clamp(2, 10)` and random sampling).

- [ ] **Step 3: Implement Cycle Deck (Exhaustion Deck) in `infinite_video_queue.dart`**

Replace the 10-item clamped history buffer with a cycle deck:
1. Maintain `_cycleDeck`: a copy of `_pool` shuffled per cycle.
2. Maintain `_historyBuffer` scaled dynamically: `(_pool.length * 0.8).round()` to prevent consecutive repetition between cycle boundaries.
3. When selecting next items in `_generateBatch`, pick from unplayed candidates in `_cycleDeck` (balancing categories). When `_cycleDeck` is exhausted, refill it with `_pool` and reshuffle.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd apps/mobile && flutter test test/infinite_video_queue_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/services/infinite_video_queue.dart apps/mobile/test/infinite_video_queue_test.dart
git commit -m "fix(queue): guarantee 100% pool cycle coverage without repetition in InfiniteVideoQueue"
```

---

### Task 2: Video Engagement Scoring & Stale Video Detection Engine

**Files:**
- Create: `apps/mobile/lib/services/engagement_score_service.dart`
- Test: `apps/mobile/test/engagement_score_service_test.dart`

**Interfaces:**
- Consumes: `VideoItem`, `VideoWatchMetric`
- Produces: 
  - `double calculateEngagementScore(VideoItem video, VideoWatchMetric? metric, {required bool isFavorite, required bool isDownloaded, required int nowEpochMs})`
  - `List<VideoItem> rankVideosForPruning(List<VideoItem> catalog, Map<String, VideoWatchMetric> metrics, {Set<String> favoriteIds = const {}, Set<String> downloadedIds = const {}, int limit = 20})`

- [ ] **Step 1: Write the failing unit tests for engagement scoring**

In `apps/mobile/test/engagement_score_service_test.dart`:
- Test that favorite and downloaded videos receive maximum protection (score `double.infinity`).
- Test that frequently skipped videos (`skippedCount > 2 * completedCount`) have lower scores than unwatched videos.
- Test that stale unwatched videos (> 21 days in catalog without plays) are prioritized for rotation over recently added unwatched videos.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/engagement_score_service_test.dart`
Expected: FAIL (file does not exist).

- [ ] **Step 3: Implement `EngagementScoreService`**

Implement scoring algorithm:
- Score weights:
  - Base: 100.0
  - Completed play: +25.0 each
  - Watch duration: +1.0 per 60 seconds
  - Skip penalty: -30.0 each if watched < 15 seconds
  - Stale unviewed penalty: -5.0 per week since added if `watchCount == 0`
  - Protection rule: If `isFavorite` or `isDownloaded`, score = `double.infinity`.
- Pruning rank: Sort ascending (lowest score first), filtering out protected items.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd apps/mobile && flutter test test/engagement_score_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/services/engagement_score_service.dart apps/mobile/test/engagement_score_service_test.dart
git commit -m "feat: implement EngagementScoreService for identifying stale and disliked videos"
```

---

### Task 3: Followed Channels Table & Channel Rotator Service

**Files:**
- Modify: `apps/mobile/lib/services/database_service.dart`
- Create: `apps/mobile/lib/models/followed_channel.dart`
- Create: `apps/mobile/lib/services/catalog_rotator_service.dart`
- Test: `apps/mobile/test/catalog_rotator_service_test.dart`

**Interfaces:**
- Consumes: `DatabaseService`, `YouTubeExplorerService`
- Produces:
  - SQLite table `followed_channels`: `channel_id`, `title`, `handle`, `logo_url`, `auto_sync`, `last_synced_at`, `added_at`.
  - `DatabaseService.getFollowedChannels() -> Future<List<FollowedChannel>>`
  - `DatabaseService.saveFollowedChannel(FollowedChannel channel) -> Future<void>`
  - `DatabaseService.removeFollowedChannel(String channelId) -> Future<void>`
  - `CatalogRotatorService.fetchFreshChannelVideos(...) -> Future<List<VideoItem>>`

- [ ] **Step 1: Write the failing tests for channel persistence and fresh video fetching**

In `apps/mobile/test/catalog_rotator_service_test.dart`:
- Test inserting and retrieving followed channels.
- Test that fresh video fetching excludes IDs already in `videos` and `deleted_videos`.
- Test that fresh video items receive correct `categoryId` and metadata.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/catalog_rotator_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement schema migration & `CatalogRotatorService`**

1. In `database_service.dart`, add `followed_channels` table creation to database open/init.
2. Pre-populate starter channels if table is empty:
   - `@peppapig`, `@CoComelon`, `Ms Rachel`, `Super Simple Songs`.
3. In `CatalogRotatorService`, query `YouTubeExplorerService.getChannelVideos(channel.handle)`:
   - Filter out existing videos in database.
   - Filter out deleted videos from `getDeletedVideoIds()`.
   - Take up to N newest items per channel.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd apps/mobile && flutter test test/catalog_rotator_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/models/followed_channel.dart apps/mobile/lib/services/database_service.dart apps/mobile/lib/services/catalog_rotator_service.dart apps/mobile/test/catalog_rotator_service_test.dart
git commit -m "feat: add followed_channels persistence and CatalogRotatorService"
```

---

### Task 4: 200-Video Catalog Cap & Automated Pruning Policy in `AppProvider`

**Files:**
- Modify: `apps/mobile/lib/services/database_service.dart`
- Modify: `apps/mobile/lib/providers/app_provider.dart`
- Test: `apps/mobile/test/catalog_cap_and_prune_test.dart`

**Interfaces:**
- Consumes: `EngagementScoreService`, `CatalogRotatorService`, `DatabaseService`
- Produces:
  - `AppProvider.syncAndRotateCatalog({bool forceManual = false}) -> Future<RotationSummary>`
  - `AppProvider.pruneStaleVideos(List<String> videoIds) -> Future<void>`
  - `AppProvider.isCatalogNearLimit -> bool` (true if >= 180 / 200)
  - `AppProvider.catalogLimit -> int` (200)

- [ ] **Step 1: Write failing unit test for catalog cap enforcement**

In `apps/mobile/test/catalog_cap_and_prune_test.dart`:
- Test that when 20 new videos are added to a library of 195 videos:
  - If `autoRotateCatalog` is true, exactly 15 lowest-scoring unpinned/non-favorite videos are pruned, leaving total count at 200.
  - Test that favorite and downloaded videos are never pruned.
  - Test that parent is notified via state flags if library reaches >= 180 items.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/catalog_cap_and_prune_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement 200 cap and pruning workflow in `AppProvider`**

1. Add settings: `auto_rotate_catalog` (default true) and `catalog_max_limit` (200).
2. Implement `pruneStaleVideosToFit(int incomingCount)`:
   - Identify candidate count needed: `(currentCount + incomingCount) - 200`.
   - If candidate count > 0:
     - Use `EngagementScoreService.rankVideosForPruning` to find the worst-performing unpinned, non-favorite videos.
     - Delete candidate videos and update `deleted_videos` or unpin them.
3. In `syncAndRotateCatalog()`:
   - Fetch fresh videos from followed channels.
   - Run `pruneStaleVideosToFit(freshVideos.length)`.
   - Insert fresh videos.
   - Notify listeners with `RotationSummary(addedCount, prunedCount)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd apps/mobile && flutter test test/catalog_cap_and_prune_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/providers/app_provider.dart apps/mobile/lib/services/database_service.dart apps/mobile/test/catalog_cap_and_prune_test.dart
git commit -m "feat: enforce 200-video catalog cap and auto-rotation in AppProvider"
```

---

### Task 5: Parent Dashboard UI: Catalog Limit Alert, Smart Cleanup Sheet, and "Get Fresh Videos" Action

**Files:**
- Modify: `apps/mobile/lib/screens/parent_dashboard_screen.dart`
- Modify: `apps/mobile/lib/screens/parent_media_library_screen.dart`
- Modify: `apps/mobile/lib/screens/parent_youtube_search_screen.dart`
- Create: `apps/mobile/lib/widgets/smart_cleanup_sheet.dart`
- Test: `apps/mobile/test/catalog_management_ui_test.dart`

**Interfaces:**
- Consumes: `AppProvider` rotation and catalog cap methods.
- Produces:
  - **Overview / Media Library Banner**: Shows "Catalog: X / 200 videos" with warning badge when >= 180.
  - **"Get Fresh Videos" Quick Action Button**: Triggers `syncAndRotateCatalog` with animated progress indicator.
  - **Smart Cleanup Sheet**: Lists suggested stale videos with stats (Skip rate, Days unwatched) and single-tap "Clean Up Selected" button.
  - **Follow Channel Toggle**: Switch on `ParentYouTubeSearchScreen` channel header to subscribe/unsubscribe a channel from auto-rotation.

- [ ] **Step 1: Write widget test for catalog management UI**

In `apps/mobile/test/catalog_management_ui_test.dart`:
- Test that catalog capacity indicator displays `X / 200`.
- Test that tapping "Get Fresh Videos" triggers provider rotation and displays completion snackbar.
- Test that Smart Cleanup sheet presents stale videos and allows parent confirmation.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/catalog_management_ui_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement UI components**

1. Create `SmartCleanupSheet`:
   - Bottom sheet displaying ranked candidate videos for removal with checkmarks, skip counts, and watch time.
   - Action button: "Remove Selected (N)".
2. In `parent_dashboard_screen.dart`:
   - Add Catalog Health card in Overview tab: `142 / 200 Videos`, [🔄 Get Fresh Videos] button, [🧹 Smart Cleanup] button.
   - Display warning banner when `allVideos.length >= 180`.
3. In `parent_youtube_search_screen.dart`:
   - When viewing a channel search result, add a "Follow Channel for Auto-Rotation" toggle button.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd apps/mobile && flutter test test/catalog_management_ui_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/screens/ apps/mobile/lib/widgets/smart_cleanup_sheet.dart apps/mobile/test/catalog_management_ui_test.dart
git commit -m "feat(ui): add Catalog Cap indicator, Get Fresh Videos action, and Smart Cleanup sheet"
```

---

### Task 6: Full Integration Test & Verification

**Files:**
- Test: `apps/mobile/test/catalog_rotation_integration_test.dart`

- [ ] **Step 1: Write comprehensive integration test**

Verify the end-to-end flow:
1. Seed database with 200 videos (some marked as favorites, some with high skip counts, some unwatched).
2. Follow 2 test channels.
3. Call `syncAndRotateCatalog()`.
4. Verify:
   - New videos are inserted.
   - Total videos does NOT exceed 200.
   - Favorite videos are 100% preserved.
   - Previously deleted videos are NOT re-added.
   - `InfiniteVideoQueue` plays the catalog through a non-repeating cycle deck.

- [ ] **Step 2: Run all tests in mobile app**

Run: `cd apps/mobile && flutter test`
Expected: All tests pass (including previous 128 tests and all new tests).

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/test/
git commit -m "test: add end-to-end integration test for catalog rotation, pruning, and playback cycle"
```

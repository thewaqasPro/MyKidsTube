# Android Native Parity Checklist & Architecture Plan

This document tracks feature and architectural parity for the native Android implementation (`apps/mobile-android/`) against the reference Flutter implementation (`apps/mobile/`) and React Native implementation (`apps/mobile-rn/`).

---

## 1. Screens & Navigation

| Screen | Flutter (`apps/mobile/lib/screens/`) | React Native (`apps/mobile-rn/src/screens/`) | Native Android Planned Component | Status | Notes |
|---|---|---|---|:---:|---|
| Device Pairing | `device_pairing_screen.dart` | `DevicePairingScreen.tsx` | `DevicePairingScreen.kt` | [ ] | 6-digit code (`ABC-234`), 5-min timeout, exp backoff (2.5s→10s), unmount cancel, no skip backdoor |
| Parent Gate Dialog | `parent_gate_dialog.dart` | `ParentGateModal.tsx` | `ParentGateDialog.kt` | [ ] | Salted SHA-256 PIN entry (masked via `PasswordVisualTransformation`), gates all parent areas, forces PIN change if default (1234) |
| Parent Dashboard | `parent_dashboard_screen.dart` | `ParentDashboardScreen.tsx` | `ParentDashboardScreen.kt` | [ ] | Executive stats (total videos, downloads, cache size, server ping, today watch time), navigation tiles, prune safety cap alerts, catalog sync |
| Parent Security | `parent_security_screen.dart` | `ParentSecurityScreen.tsx` | `ParentSecurityScreen.kt` | [ ] | Current → new → confirm PIN, min 4 numeric digits, forced change while default PIN (1234) active |
| Parent Media Library | `parent_media_library_screen.dart` | `ParentMediaLibraryScreen.tsx` | `ParentMediaLibraryScreen.kt` | [ ] | Ingest URL form (category & quality selection), multi-select bulk delete, search and category filtering |
| Parent Storage | `parent_storage_screen.dart` | `ParentStorageScreen.tsx` | `ParentStorageScreen.kt` | [ ] | Storage usage gauge, Download All with pre-flight space check, Clear Cache, Reset, per-item delete |
| Parent Server & Pairing | `parent_server_screen.dart` | `ParentServerScreen.tsx` | `ParentServerScreen.kt` | [ ] | VPS endpoint setting with persistence, ping latency test, pairing code status & regeneration |
| Parent Analytics | `parent_analytics_screen.dart` | `ParentAnalyticsScreen.tsx` | `ParentAnalyticsScreen.kt` | [ ] | Screen time KPI, completion/skip funnel, daily watch trend, top loved/skipped videos, Cloudflare sync |
| Kid Profile Switcher | `profile_selector_dialog.dart` / `kid_profile_switcher_sheet.dart` | `KidProfileSwitcherSheet.tsx` | `KidProfileSwitcherSheet.kt` | [ ] | Modal bottom sheet with avatar selection, switch child profile, reload profile catalog |
| Kid Home | `kid_home_screen.dart` | `KidHomeScreen.tsx` | `KidHomeScreen.kt` | [ ] | WonderKids feed, category filter pills, horizontal shorts shelf, search overlay, profile switcher, grown-ups gate |
| Kid Player | `kid_player_screen.dart` | `KidPlayerScreen.tsx` | `KidPlayerScreen.kt` | [ ] | Offline-first Media3 ExoPlayer playback → sandboxed WebView embed fallback, 3s-hold touch lock, related videos queue, keep-awake |
| Kid Shorts Feed | `kid_shorts_feed_screen.dart` | `KidShortsFeedScreen.tsx` | `KidShortsFeedScreen.kt` | [ ] | 9:16 vertical paging feed (VerticalPager), action rail (favorite, mute, auto-advance, lock), 3s touch lock, keep-awake |

---

## 2. UI Components & Widgets

| Widget | Flutter | React Native | Native Android Planned Component | Status | Notes |
|---|---|---|---|:---:|---|
| Video Card | `video_card.dart` | `VideoCard.tsx` | `VideoCard.kt` | [ ] | 16:9 thumbnail, duration pill, channel avatar/name, title, offline indicator, favorite toggle |
| Video Tile | `video_tile.dart` | `VideoTile.tsx` | `VideoTile.kt` | [ ] | Compact horizontal card for lists and related queue |
| Kid Embed Player | `kid_embed_player.dart` | `KidEmbedPlayer.tsx` | `KidEmbedPlayer.kt` | [ ] | Sandboxed Android WebView, youtube-nocookie.com lockdown, click-jacking shields over branding |
| Touch Lock Overlay | `touch_lock_overlay.dart` | `TouchLockOverlay.tsx` | `TouchLockOverlay.kt` | [ ] | Absorbs touch events, 3-second hold to unlock with circular progress & haptic feedback |
| Shorts Action Rail | `shorts_action_rail.dart` | `ShortsActionRail.tsx` | `ShortsActionRail.kt` | [ ] | Favorite star, Mute/unmute, Auto-advance toggle, Toddler touch lock button |
| Child Avatar | `child_avatar.dart` | `ChildAvatar.tsx` | `ChildAvatar.kt` | [ ] | Gradient background, avatar icons (bear, lion, unicorn, rocket, etc.) |
| Orientation Mode Switch | `orientation_mode_switch.dart` | `OrientationModeSwitch.tsx` | `OrientationModeSwitch.kt` | [ ] | Auto / Portrait / Landscape mode switcher |
| Ambient Blur Background | `ambient_blur_background.dart` | `AmbientBlurBackground.tsx` | `AmbientBlurBackground.kt` | [ ] | Soft blurred background behind video |

---

## 3. Services & Infrastructure

| Layer / Service | Flutter | React Native | Native Android Counterpart | Status | Notes |
|---|---|---|---|:---:|---|
| Database Service | `database_service.dart` | `DatabaseService.ts` | Room Database (`AppDatabase.kt`, DAOs) | [ ] | Tables: `videos`, `categories`, `settings`, `local_child_profiles`, `local_watch_events`, `favorites`. Transactional batch upsert, prune safety cap (<=50%) |
| VPS API Service | `vps_api_service.dart` | `VpsApiService.ts` | Retrofit / OkHttp (`KidsTubeApi.kt`, `VpsApiService.kt`) | [ ] | Register device, status check, catalog (`all_videos`), profiles, ingest, delete, watch metrics sync, health ping. Parent auth cookie & bearer handling |
| Download Service | `download_service.dart` | `DownloadService.ts` | WorkManager (`DownloadWorker.kt`, `DownloadManager.kt`) | [ ] | Max 2 concurrent downloads, `.part` files with HTTP Range resume, size verification against catalog, atomic rename, ENOSPC storage-full check, throttled progress updates (<=4Hz), orphan cleanup |
| PIN Security | `app_provider.dart` | `SecurityService.ts` | `SecurityService.kt` | [ ] | Salted SHA-256 PIN storage (16-byte random SecureRandom salt), EncryptedSharedPreferences for token & salt, no plaintext PIN |
| Settings Store | SQLite `settings` table | AsyncStorage | DataStore Preferences (`SettingsDataStore.kt`) + Room | [ ] | Server URL, device name, paired status, active profile ID, orientation mode |
| Dependency Injection | Provider | Singleton / Context | Hilt (`AppModule.kt`) | [ ] | Injects Api, Database, DataStore, Security, Repositories into ViewModels |

---

## 4. API Contract Compliance

| Endpoint | Method | Expected Payload / Response | Native Android Implementation | Status | Notes |
|---|---|---|---|:---:|---|
| `/api/v1/health` | GET | `{ status: "ok", service: "..." }` | `checkHealth()`, `pingHealth()` | [ ] | 8s timeout, computes round-trip latency |
| `/api/v1/devices/register` | POST | Request: `{ device_name }` -> `{ device_id, pairing_code, expires_in_seconds }` | `registerDevice()` | [ ] | Sanitize device name |
| `/api/v1/devices/status/:code` | GET | Response: `status` ('pending' / 'paired' / 'expired'), `auth_token`, `profile` | `checkDeviceStatus()` | [ ] | Atomically claims device auth token on 'paired' |
| `/api/v1/catalog` | GET | Response: `{ sections, all_videos, categories, profiles, source }` | `fetchCatalog()` | [ ] | **CRITICAL: Uses `all_videos` key (NOT `videos`)**, supports `?profile_id=` |
| `/api/v1/profiles` | GET | Array of child profiles `[{ id, name, avatar_icon, age_bracket }]` | `fetchProfiles()` | [ ] | Syncs remote profiles to Room |
| `/api/auth/login` | POST | Request: `{ pin }` -> Sets `kidstube_parent_session` cookie | `loginParent()` | [ ] | Authenticates parent role with server |
| `/api/v1/ingest` | POST | Request: `{ url, category_id, quality, allowed_profile_ids }` | `ingestUrl()` | [ ] | Requires parent role credential (Cookie / Bearer) |
| `/api/studio/videos?ids=...` | DELETE | Query param `ids=...` | `deleteVideos()` | [ ] | Requires parent role credential |
| `/api/metrics/watch` | POST | Request: `{ events: [...] }` | `syncWatchEvents()` | [ ] | Batch sync of local watch events; accepts device or parent token |

---

## 5. Non-Negotiables & Strict Rules

| Rule | Requirement | Native Android Implementation | Status |
|---|---|---|:---:|
| Catalog Key | Server returns `all_videos`, NOT `videos` | Explicit `@SerialName("all_videos")` in `CatalogResponseDto` + unit tests against sample JSON | [ ] |
| Parent Authentication | Parent-only endpoints require parent session | Calls `POST /api/auth/login` with parent PIN; uses `JavaNetCookieJar` with `CookieManager` or Bearer header; no dead buttons | [ ] |
| No Backdoor | No skip-pairing backdoor or bypass | Fresh install must complete pairing flow | [ ] |
| Salted SHA-256 PIN | 16-byte SecureRandom salt, never plaintext | `SecurityService` with `EncryptedSharedPreferences`, force change on default 1234 PIN, masked PIN entry | [ ] |
| Persisted VPS URL | Read saved endpoint on startup, default only when none exists | Read from DataStore / Settings on startup | [ ] |
| Resilient Downloads | WorkManager + OkHttp with HTTP Range resume | `.part` file detection, `Range: bytes=offset-`, atomic rename to `.mp4`, size verification, ENOSPC check, orphan cleanup | [ ] |
| Guarded Prune | Never delete on empty/failed catalog | Guarded prune logic: only prune on valid non-empty catalog or explicit signal; >50% held for confirmation | [ ] |
| Pairing Poll Backoff | 5-min timeout, exponential backoff (2.5s -> 10s), cancel on screen destroy | Coroutine Job launched in ViewModel, cancelled in `onCleared()` / screen exit | [ ] |
| WebView Lockdown | Strict origin and navigation control | `WebViewClient` blocks anything outside `youtube-nocookie.com`, `about:blank`, transparent shields over YouTube links | [ ] |
| Android Security Config | Block cleartext except localhost / 10.0.2.2 | `network_security_config.xml` configured, `allowBackup="false"` | [ ] |
| Lifecycle & Media3 | Release ExoPlayer properly, keep-awake during playback | `DisposableEffect` / lifecycle cleanup, `FLAG_KEEP_SCREEN_ON` on player screens | [ ] |

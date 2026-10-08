# Flutter to React Native Parity Checklist
This document tracks feature and architectural parity between the reference Flutter implementation (`apps/mobile/`) and the React Native + TypeScript implementation (`apps/mobile-rn/`).

---

## 1. Screens & Navigation

| Flutter Screen (`apps/mobile/lib/screens/`) | React Native Counterpart (`apps/mobile-rn/src/screens/`) | Status | Notes |
|---|---|:---:|---|
| `device_pairing_screen.dart` | `DevicePairingScreen.tsx` | [x] | 6-digit code (`ABC-234`), 5-min timeout, exp backoff, unmount cancel, no skip backdoor |
| `parent_gate_dialog.dart` | `ParentGateModal.tsx` | [x] | Math challenge or salted PIN entry, gates all parent features |
| `parent_dashboard_screen.dart` | `ParentDashboardScreen.tsx` | [x] | Executive stats, navigation tiles, prune safety cap alerts, catalog sync |
| `parent_security_screen.dart` | `ParentSecurityScreen.tsx` | [x] | Current -> new -> confirm PIN, >=4 digits, forced change if default PIN (1234) |
| `parent_media_library_screen.dart` | `ParentMediaLibraryScreen.tsx` | [x] | Ingest URL form, category/quality select, multi-select bulk delete, search filter |
| `parent_storage_screen.dart` | `ParentStorageScreen.tsx` | [x] | Storage usage gauge, Download All, Clear Storage, Cache Reset, offline file list |
| `parent_server_screen.dart` | `ParentServerScreen.tsx` | [x] | VPS endpoint setting, ping latency test, pairing code status |
| `parent_analytics_screen.dart` | `ParentAnalyticsScreen.tsx` | [x] | Screen time KPI, attention funnel, 7-day trend, top videos, cloud sync |
| `profile_selector_dialog.dart` | `KidProfileSwitcherSheet.tsx` | [x] | Switch child profile, load profile catalog, create profile modal |
| `kid_home_screen.dart` | `KidHomeScreen.tsx` | [x] | YouTube-style feed, horizontal category pills, shorts shelf, search, profile switcher |
| `kid_player_screen.dart` | `KidPlayerScreen.tsx` | [x] | Native MP4 -> embed fallback, toddler touch lock (3s hold), seek, related list |
| `kid_shorts_feed_screen.dart` | `KidShortsFeedScreen.tsx` | [x] | 9:16 vertical paging feed, 3-controller window, action rail, touch lock |

---

## 2. Widgets & UI Components

| Flutter Widget (`apps/mobile/lib/widgets/`) | React Native Component (`apps/mobile-rn/src/components/`) | Status | Notes |
|---|---|:---:|---|
| `video_card.dart` | `VideoCard.tsx` | [x] | 16:9 thumbnail, duration pill, channel avatar, title, offline checkmark |
| `video_tile.dart` | `VideoTile.tsx` | [x] | Compact horizontal tile for lists and related queue |
| `kid_embed_player.dart` | `KidEmbedPlayer.tsx` | [x] | Sandboxed WebView, click-jacking shields, blocked external URLs |
| `touch_lock_overlay.dart` | `TouchLockOverlay.tsx` | [x] | Absorb touches, 3-second hold to unlock with circular progress & haptic |
| `shorts_action_rail.dart` | `ShortsActionRail.tsx` | [x] | Favorite star, Mute/unmute, Auto-advance vs loop toggle, Lock button |
| `child_avatar.dart` | `ChildAvatar.tsx` | [x] | Gradient background, avatar icons (bear, lion, unicorn, rocket, etc.) |
| `kid_profile_switcher_sheet.dart` | `KidProfileSwitcherSheet.tsx` | [x] | Bottom sheet with profile avatars, switch child profile, parent gate trigger |
| `orientation_mode_switch.dart` | `OrientationModeSwitch.tsx` | [x] | Portrait / Landscape / Auto switcher |
| `ambient_blur_background.dart` | `AmbientBlurBackground.tsx` | [x] | Blurred background for video aspect fill |

---

## 3. Services & Infrastructure

| Flutter Service (`apps/mobile/lib/services/`) | React Native Service (`apps/mobile-rn/src/services/`) | Status | Notes |
|---|---|:---:|---|
| `database_service.dart` | `DatabaseService.ts` | [x] | SQLite tables (`videos`, `categories`, `settings`, `local_child_profiles`, `local_watch_events`, `favorites`). Batch transaction upsert, prune safety cap (<=50%), corrupt DB recovery |
| `vps_api_service.dart` | `VpsApiService.ts` | [x] | Register device, status check, catalog, profiles, ingest, delete, watch sync, health ping. Bearer token auth header, HTTPS enforcement |
| `download_service.dart` | `DownloadService.ts` | [x] | Max 2 concurrent downloads, `.part` files with HTTP Range resume, size verification against catalog, atomic rename, ENOSPC storage full check, throttled progress updates (<=4Hz), orphan cleanup |
| PIN security (`app_provider.dart`) | `SecurityService.ts` | [x] | Salted SHA-256 PIN storage (16-byte random salt), secure storage for token & salt, no plaintext PIN |

---

## 4. State Management & Models

| Flutter Architecture | React Native Counterpart | Status | Notes |
|---|---|:---:|---|
| `AppProvider` (`providers/app_provider.dart`) | `useAppStore.ts` (Zustand) | [x] | Mirroring all state: pairing state, catalog, downloads, profiles, orientation, safety cap |
| `VideoItem` (`models/video_item.dart`) | `types/video.ts` | [x] | Full schema: id, duration, categoryId, sourceUrl, streamUrl, isShort, effectiveYoutubeId, etc. |
| `CategoryItem` (`models/category_item.dart`) | `types/video.ts` | [x] | Schema: id, name, icon, displayOrder |
| `ChildProfile` (`models/child_profile.dart`) | `types/profile.ts` | [x] | Schema: id, name, avatarIcon, ageBracket |
| `KidColors` / `KidTheme` (`utils/constants.dart`)| `theme/colors.ts` | [x] | Exact WonderKids color palette tokens & dark theme |
| URL helpers (`apps/portal/src/lib/constants.ts`) | `utils/urlHelpers.ts` | [x] | `getThumbnailUrl`, `getStreamUrl`, `getYoutubeId`, `getYoutubeEmbedUrl`, `isVideoShort` |

---

## 5. API Contract Compliance

| Endpoint | Method | Status | Expected Response & Logic |
|---|---|:---:|---|
| `/api/v1/health` | GET | [x] | `{ status: "ok", service: "..." }` |
| `/api/v1/devices/register` | POST | [x] | Request: `{ device_name }` -> `{ device_id, pairing_code, expires_in_seconds }` |
| `/api/v1/devices/status/:code` | GET | [x] | Status check: `pending` vs `paired`, claims `auth_token` atomically |
| `/api/v1/catalog` | GET | [x] | Sections, categories, all_videos, profiles; respects `profile_id` query param |
| `/api/v1/profiles` | GET | [x] | Array of child profiles |
| `/api/v1/ingest` | POST | [x] | Request: `{ url, category_id, quality, allowed_profile_ids }` |
| `/api/metrics/watch` | POST | [x] | Batch sync of local watch events |
| `/api/studio/videos?ids=...` | DELETE | [x] | Bulk delete videos by comma-separated IDs |

---

## 6. Non-Negotiables & Security Rules

| Requirement | Status | Notes |
|---|:---:|---|
| No skip-pairing backdoor | [x] | Fresh install always requires pairing code authorization |
| Salted SHA-256 PIN in secure storage | [x] | 16-byte random salt per install; forced change on default 1234 PIN |
| Persisted VPS URL | [x] | Reads saved `vps_url` on init; only writes default when missing |
| Resilient Download Engine | [x] | Max 2 concurrent, `.part` download, HTTP Range resume, size check, atomic rename, storage-full error |
| Guarded Catalog Prune | [x] | Prune only on valid non-empty catalog or explicit server signal; <=50% safety cap |
| Pairing Poll Backoff | [x] | 5 min timeout, exponential backoff (2.5s -> 10s), unmount cancel |
| Defensive Parsing | [x] | Malformed items never crash the app; single transaction catalog batch upsert |
| Network Security Config | [x] | Cleartext blocked except localhost/10.0.2.2/127.0.0.1; HTTPS enforced by default |
| Android & iOS configs | [x] | `allowBackup="false"`, backup exclusion rules for DB and Keystore, proper permissions |

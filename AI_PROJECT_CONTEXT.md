# AI_PROJECT_CONTEXT.md — MyKidsTube (KidsTube Monorepo)

> **Last Reviewed:** 2026-10-13  
> **Repository Root:** `MyKidsTube/`  
> **Verification Status:** Verified against actual repository source files, package manifests (`apps/portal/package.json`, `apps/mobile/pubspec.yaml`, `apps/mobile-android/app/build.gradle.kts`, `apps/server/docker-compose.yml`), database migrations (`apps/portal/migrations/`), and engineering documentation (`DESIGN.md`, `docs/`).

---

## 1. Project Overview

### Project Name & Purpose
- **Project Name:** **MyKidsTube** (also referenced as **KidsTube**; Flutter package name `safe_tube`, Android namespace `com.mykidstube.android`, Cloudflare Worker name `mykidstube`).
- **Purpose:** A distraction-free, childproof, offline-first kids video player and parent-curated streaming platform backed by a Cloudflare Edge API/Portal (`apps/portal`), a self-hosted Dockerized VPS media streamer (`apps/server`), and cross-platform/native mobile apps (`apps/mobile` in Flutter and `apps/mobile-android` in Kotlin/Jetpack Compose).

### Business Goals & Primary Users
- **Business / Product Goals:**
  - Replicate the familiar, responsive interface of YouTube/YouTube Kids while stripping away all algorithmic rabbit holes, recommendation feeds from unverified sources, social triggers, and visual noise (`DESIGN.md`).
  - Minimize infrastructure costs by running API/database metadata on Cloudflare Workers + D1 free/edge tier and offloading heavy MP4 streaming to a low-cost 1 GB RAM / 1 vCPU VPS running zero-copy Nginx HTTP 206 byte-range streaming (`docs/vps-optimization-1gb.md`).
  - Provide zero-VPS-bandwidth offline playback on kids' tablets/phones via local SQLite catalog caching and background MP4 downloading (`docs/architecture.md`).
- **Primary Users:**
  1. **Parents / Guardians (Administrators):** Curate video catalogs via single URLs or YouTube playlists, manage child profiles (e.g., *Maya*, *Noah*, *Leo*, *Ali*, *Fatima*, *Omar*), pair devices via 6-digit codes, manage security (Master Accounts, WebAuthn Passkeys, 4–6 digit Child Gate PIN), monitor local disk usage, and review per-child viewing & retention analytics.
  2. **Children (Viewers — Toddlers, Early Readers, Big Kids):** Watch curated long-form landscape videos (16:9) and authentic vertical Shorts (9:16) with childproof controls (3-second hold-to-unlock touch lock, hardware back-gesture interception, zero external links, zero comments/dislikes).

### Current Development Status
- **Status:** Active production/pre-production monorepo (`version: 1.0.0+1` in Flutter `apps/mobile`, `1.0.0` in `apps/mobile-android`, `0.0.1` in `apps/portal`).
- **Completed Milestones (Verified in `docs/ai-workflow.md` & `apps/mobile-android/PARITY-ANDROID.md`):**
  - Cloudflare Workers + Astro SSR Parent Web Portal & Kids Web Portal (`apps/portal`).
  - Drizzle ORM schema + 8 SQL migrations (`0000_initial_schema.sql` through `0007_passkey_columns_fix.sql`) on Cloudflare D1.
  - Dual-mode Parent Authentication: Better Auth (Email/Password Master Accounts + WebAuthn Passkeys) alongside 4–6 digit salted/hashed PIN gates (`apps/portal/src/lib/auth.ts`, `apps/portal/src/lib/parentAuth.ts`).
  - Modularized Portal codebase with `@/*` path aliases, domain repositories (`catalog.repository.ts`, `devices.repository.ts`), services (`catalog.service.ts`, `analytics.service.ts`), and decomposed React 19 UI components.
  - Flutter mobile client (`apps/mobile`) with offline downloads, 6-digit pairing, multi-kid profile switching, local-first watch analytics buffering, Shorts vs. Landscape aspect-ratio isolation, and 5-screen modular Parent Dashboard.
  - Native Android client (`apps/mobile-android`) with Kotlin 2.0, Jetpack Compose, Media3 ExoPlayer, Room, WorkManager, and Hilt achieving feature parity with the Flutter client.

### Important URLs, Environments & Integrations
- **Cloudflare Worker / Edge API Base URL:** `https://mykidstube.kidstube.workers.dev/api` (configured in `apps/portal/wrangler.json`, account ID `e625c672ee355cd19487de814338560a`, D1 database `mykidstube`).
- **VPS Media Streaming Host:** `https://kidsapi.waqas.pro/media/videos/{youtube_id}.mp4` and `/media/thumbs/{youtube_id}.webp` (also documented as `http://<VPS_IP>:8080/` or port `80`/`443` via `apps/server/nginx/nginx.conf`).
- **Local Development URLs:**
  - Astro Portal (`make portal` / `pnpm dev` in `apps/portal`): `http://localhost:4321` (Studio at `/studio`, Login at `/login`, Upload at `/upload`, Shorts at `/shorts`, Watch at `/watch/[id]`).
  - Local Docker Nginx Media Server (`make server`): `http://localhost:80` / `https://localhost:443` (internal cleanup service on `127.0.0.1:8081`).
- **External Integrations:**
  - **YouTube oEmbed & InnerTube Playlist Extraction:** `apps/portal/src/shared/utils/youtube.ts` and `apps/portal/src/shared/utils/innertubePlaylist.ts`.
  - **YouTube Sandboxed Embed Fallback:** `https://www.youtube-nocookie.com` locked-down WebView when an MP4 is not yet cached/hosted on the VPS (`kid_embed_player.dart`, `KidEmbedPlayer.kt`, `@videojs/react` + `@videojs/youtube-video` on web).
  - **CLI Media Ingestion Pipeline:** `yt-dlp`, `ffmpeg` / HandBrake, and `rsync` orchestrated via `scripts/sync-mykidstube.sh`, `scripts/rename_videos.py`, and `scripts/sync_to_d1.py`.

---

## 2. Technology Stack (Confirmed Facts)

### Programming Languages
- **TypeScript / JavaScript (ESM):** Web Portal & Edge API (`apps/portal`, TypeScript `^7.0.2`, Node.js `>=22.12.0`).
- **Dart:** Cross-platform Mobile Client (`apps/mobile`, Dart SDK `^3.6.1`).
- **Kotlin:** Native Android Client (`apps/mobile-android`, Kotlin 2.0, JVM target `17`, `compileSdk = 35`, `minSdk = 26`, `targetSdk = 35`).
- **Python 3:** VPS cleanup microservice (`apps/server/cleanup_service.py` on `python:3.11-alpine`) and host media operations scripts (`scripts/rename_videos.py`, `scripts/sync_to_d1.py`, `scripts/upload_playlist_videos.py`).
- **SQL (SQLite dialect):** Cloudflare D1 migrations (`apps/portal/migrations/*.sql`), mobile `sqflite` (`kidstube_v2.db`), and Android Room database.
- **Bash / Shell & Make:** Developer workflow & VPS sync automation (`Makefile`, `scripts/*.sh`).

### Frameworks, Libraries & Exact Package Versions

#### A. Parent & Kids Web Portal (`apps/portal/package.json`)
- **Framework & SSR Adapter:** `astro` (`^7.3.5`), `@astrojs/cloudflare` (`^14.3.3`, `output: 'server'`), `@astrojs/react` (`^7.0.0`)
- **UI & Styling:** `react` (`^19.3.0`), `react-dom` (`^19.3.0`), `tailwindcss` (`^4.3.3`), `@tailwindcss/vite` (`^4.3.3`), `lucide-react` (`^1.52.0`)
- **Video Playback (Web):** `@videojs/react` (`10.0.1`), `@videojs/youtube-video` (`10.0.1`)
- **ORM & Database:** `drizzle-orm` (`^0.45.3`), `drizzle-kit` (`^0.31.11`), `@libsql/client` (`^0.18.0`)
- **Authentication:** `better-auth` (`^1.7.7`), `@better-auth/drizzle-adapter` (`^1.7.7`), `@better-auth/passkey` (`^1.7.7`)
- **Typing:** `@cloudflare/workers-types` (`^5.20261007.1`), `typescript` (`^7.0.2`)

#### B. Flutter Mobile App (`apps/mobile/pubspec.yaml`)
- **State Management:** `provider` (`^6.1.2`)
- **Networking & Caching:** `dio` (`^5.7.0`), `cached_network_image` (`^3.4.1`)
- **Video & WebView:** `video_player` (`^2.9.2`), `webview_flutter` (`^4.14.1`), `webview_flutter_android` (`^4.14.1`), `webview_flutter_wkwebview` (`^3.16.1`), `wakelock_plus` (`^1.2.8`)
- **Local Persistence & Security:** `sqflite` (`^2.4.1`), `path_provider` (`^2.1.4`), `path` (`^1.9.0`), `flutter_secure_storage` (`^9.2.4`), `crypto` (`^3.0.6`)
- **Testing & Linting:** `flutter_test`, `flutter_lints` (`^5.0.0`), `sqflite_common_ffi` (`^2.4.3`)

#### C. Native Android App (`apps/mobile-android/app/build.gradle.kts`)
- **UI:** Jetpack Compose BOM `2024.10.01`, Material3, `activity-compose:1.9.3`, `navigation-compose:2.8.3`, `coil-compose:2.7.0`
- **DI & Architecture:** Dagger Hilt `2.52`, Lifecycle/ViewModel Compose `2.8.7`
- **Media:** AndroidX Media3 ExoPlayer `1.4.1` (`media3-exoplayer`, `media3-ui`, `media3-common`), `androidx.webkit:webkit:1.12.1`
- **Storage & Background Work:** Room `2.6.1`, DataStore Preferences `1.1.1`, Security Crypto `1.1.0-alpha06`, WorkManager `2.10.0`
- **Networking:** Retrofit `2.11.0`, OkHttp `4.12.0`, Kotlinx Serialization JSON `1.7.3`

#### D. VPS Media Server (`apps/server/docker-compose.yml`)
- **Reverse Proxy / Streamer:** `nginx:alpine` (`safekids_nginx`, `mem_limit: 64m`, `cpus: 0.25`)
- **Media Cleanup Service:** `python:3.11-alpine` (`safekids_cleaner`, `mem_limit: 32m`, `cpus: 0.10`, port `127.0.0.1:8081`)

### Databases & Storage Bindings
- **Cloudflare D1 (`binding: "DB"`):** SQLite edge database (`mykidstube`, ID `dce947fe-b59f-40f0-9788-c76414b476b4`).
- **Cloudflare R2 (`binding: "R2"`):** Object storage bucket `kidstube-assets` for thumbnail/asset caching.
- **VPS File Storage:** `/var/www/media/videos/*.mp4` and `/var/www/media/thumbs/*.webp` mapped from `./data/media/videos` and `./data/media/thumbs`.
- **Mobile Local Storage:** SQLite database (`kidstube_v2.db` in Flutter / Room DB in Android) + sandboxed offline media folder (`getApplicationDocumentsDirectory()/kidstube_media/`).

---

## 3. Architecture

### Monorepo Directory Structure
```text
MyKidsTube/
├── apps/
│   ├── mobile/                # Flutter Cross-Platform Client (iOS & Android)
│   │   ├── lib/
│   │   │   ├── main.dart      # App entrypoint & KidsTubeSplashScreen
│   │   │   ├── models/        # video_item.dart, child_profile.dart, category_item.dart
│   │   │   ├── providers/     # app_provider.dart (central ChangeNotifier state hub)
│   │   │   ├── screens/       # Kid feeds/players + 5 modular Parent Dashboard screens
│   │   │   ├── services/      # database_service.dart, download_service.dart, vps_api_service.dart, recommendation_service.dart
│   │   │   ├── utils/         # constants.dart, format_utils.dart, app_feedback.dart
│   │   │   └── widgets/       # video_card.dart, video_tile.dart, kid_embed_player.dart, touch_lock_overlay.dart, etc.
│   │   └── test/              # 20 unit & widget test suites
│   ├── mobile-android/        # Native Android Client (Kotlin + Jetpack Compose + Media3 + Room + WorkManager)
│   ├── portal/                # Astro SSR + React 19 Parent Studio, Web Player & Cloudflare Worker API
│   │   ├── migrations/        # 0000 to 0007 D1 SQL migrations
│   │   ├── src/
│   │   │   ├── bindings/      # env.ts (AppEnv & getAppEnv edge binding resolver)
│   │   │   ├── components/    # KidsPortal, StudioDashboard, UploadPage, WatchPage, ShortsPage, LoginPage, studio/*, upload/*, watch/*, shorts/*, auth/*
│   │   │   ├── db/            # Drizzle ORM setup (index.ts) & domain schemas (auth, catalog, profiles, analytics, devices)
│   │   │   ├── features/      # Domain repositories & services (catalog.*, devices.*, analytics.*)
│   │   │   ├── lib/           # auth.ts, auth-client.ts, parentAuth.ts, db.ts, cors.ts, vpsCleanup.ts, constants.ts
│   │   │   ├── middleware.ts  # Better Auth session injection into Astro context.locals
│   │   │   ├── pages/         # Astro routes (index, login, upload, shorts, watch/[id], studio/index) & REST API routes (/api/*)
│   │   │   └── shared/        # Standardized errors (index.ts), JSON responses (jsonResponse.ts), youtube & innertube utils
│   │   └── wrangler.json      # Cloudflare Workers, D1, and R2 configuration
│   └── server/                # Dockerized VPS Media Server
│       ├── nginx/nginx.conf   # Single-worker, zero-copy sendfile HTTP 206 byte-range config
│       ├── cleanup_service.py # Authenticated local HTTP microservice for deleting orphaned MP4/WebP files
│       └── docker-compose.yml # Resource-capped container definitions
├── docs/                      # Architecture, REST API, pairing, VPS optimization, AI workflow changelog
├── scripts/                   # CLI tools (sync-mykidstube.sh, rename_videos.py, sync_to_d1.py, build-apk.sh)
├── DESIGN.md                  # Visual design tokens, layout geometry, component specs, and prohibited anti-patterns
├── Makefile                   # Unified developer commands
└── README.md                  # Monorepo overview
```

### Data Flow & Subsystem Responsibilities
1. **API & Metadata Layer (`apps/portal` on Cloudflare Edge):**
   - Handles all catalog queries (`GET /api/v1/catalog`), profile lookups (`GET /api/v1/profiles`), 6-digit device registration & pairing (`POST /api/v1/devices/register`, `GET /api/v1/devices/status/[code]`, `POST /api/v1/devices/pair`), video ingestion (`POST /api/v1/ingest`, `POST /api/queue/add`), studio curation (`GET/PATCH/DELETE /api/studio/videos`), and batch watch-event ingestion (`POST /api/metrics/watch`).
   - Uses zero VPS CPU/RAM for database queries or session checks.
2. **Media Storage & Streaming Layer (`apps/server` on 1 GB VPS):**
   - Nginx serves static `/media/videos/{youtube_id}.mp4` and `/media/thumbs/{youtube_id}.webp` using kernel-level `sendfile` and HTTP 206 Partial Content byte-range responses.
   - `cleanup_service.py` listens on `127.0.0.1:8081` and deletes media files when authorized with `CLEANUP_SECRET`.
3. **Offline-First Mobile Clients (`apps/mobile` & `apps/mobile-android`):**
   - On launch, checks pairing status; unpaired devices display a 6-digit code and poll `/api/v1/devices/status/{code}` with exponential backoff.
   - Syncs catalog metadata from `/api/v1/catalog` into local SQLite (`DatabaseService` / Room).
   - **Playback Decision Tree:** Checks if `localPath` exists on disk first -> plays local MP4 with zero network usage; otherwise streams via Nginx HTTP 206 or falls back to sandboxed `youtube-nocookie.com` embed player.
   - **Watch Analytics Buffering:** Tracks playback duration, completion ($\ge 75\%$), and quick skips ($< 10\text{s}$) strictly in local SQLite (`local_watch_events`) with an in-memory 15-second flush ticker, syncing to Cloudflare D1 only in on-demand batches to conserve Cloudflare free-tier quotas.

### Development vs. Production Differences
- **Database Resolution (`apps/portal`):** In local development (`pnpm dev`), Astro uses Miniflare's local SQLite D1 binding (`.wrangler/state/v3/d1`). If local D1 has 0 videos, `src/lib/db.ts` includes a fallback to fetch catalog data from `API_BASE` so local UI previews still render catalog items (`docs/ai-workflow.md`).
- **Self-Healing Local Auth Tables:** `src/pages/api/auth/login.ts` and `src/lib/parentAuth.ts` auto-initialize `admin_settings` (default PIN `'1234'`) and `parent_sessions` if missing on an unmigrated local database.
- **TLS Certificates:** Local Docker server uses self-signed certs generated via `scripts/make-dev-cert.sh`; production VPS uses Certbot / Cloudflare TLS.

---

## 4. Existing Functionality & Key Entry Points

### Main Features & Modules
1. **Childproof Video Feeds & Playback:**
   - **Home Feed:** `apps/mobile/lib/screens/kid_home_screen.dart` & `apps/portal/src/components/KidsPortal.tsx` (category pills, horizontal Shorts shelf, responsive 16:9 video grid, profile avatar switcher).
   - **Landscape Watch Player:** `apps/mobile/lib/screens/kid_player_screen.dart` & `apps/portal/src/components/WatchPage.tsx` (sticky 16:9 player, `#FF0000` scrubber, 3-second hold-to-unlock `TouchLockOverlay`, up-next queue).
   - **Vertical Shorts Feed:** `apps/mobile/lib/screens/kid_shorts_feed_screen.dart` & `apps/portal/src/components/ShortsPage.tsx` (9:16 vertical swipe reel, `ShortsActionRail` / `ShortsActionPills` with favorite, mute, auto-advance, and touch lock).
2. **Strict Shorts vs. Landscape Isolation:**
   - Implemented in `apps/mobile/lib/models/video_item.dart` (`isShort` getter) and `apps/portal/src/lib/constants.ts` (`isVideoShort`):
   - Any video with `sourceUrl.contains('watch?v=')` or `duration > 70` is **always** treated as a landscape video (`isShort = false`) and routed to `KidPlayerScreen`.
   - Only authentic `/shorts/` URLs or `short_` prefixed IDs (or `categoryId == 'shorts'` with `0 < duration <= 70` and no `watch?v=`) play in `KidShortsFeedScreen`.
3. **Multi-Kid Profiles & 6-Digit Device Pairing:**
   - Profiles: `apps/mobile/lib/models/child_profile.dart`, `apps/mobile/lib/widgets/kid_profile_switcher_sheet.dart`, `apps/portal/src/db/schema/profiles.ts`.
   - Pairing: `apps/mobile/lib/screens/device_pairing_screen.dart`, `apps/portal/src/features/devices/devices.repository.ts`, `apps/portal/src/pages/api/v1/devices/*`.
4. **Parent Studio & Mobile Parent Command Center:**
   - **Web Studio (`apps/portal/src/components/StudioDashboard.tsx`):** Decomposed into `StudioOverviewTab.tsx`, `StudioVideosTab.tsx`, `StudioDevicesTab.tsx`, `StudioSecurityTab.tsx`, and `StudioAnalyticsView.tsx` (`AnalyticsKpiGrid.tsx`, `AnalyticsTrendChart.tsx`, `AnalyticsRetentionFunnel.tsx`, `AnalyticsLeaderboardTables.tsx`).
   - **Web Upload (`apps/portal/src/components/UploadPage.tsx`):** Decomposed into `UploadPlaylistCard.tsx`, `UploadBulkUrlsCard.tsx`, and `UploadBatchHelperCard.tsx`.
   - **Mobile Parent Hub (`apps/mobile/lib/screens/parent_dashboard_screen.dart`):** Routes to `parent_security_screen.dart`, `parent_media_library_screen.dart`, `parent_server_screen.dart`, `parent_storage_screen.dart`, and `parent_analytics_screen.dart`.

### Reusable Components & Utilities
- **Portal Utilities (`apps/portal/src/`):**
  - `@/bindings/env.ts`: `getAppEnv(context)` for safe Cloudflare D1/R2 binding access.
  - `@/db/index.ts`: `getDrizzle(d1)` and `getDrizzleDb(context)` for Drizzle ORM queries.
  - `@/shared/response/jsonResponse.ts`: `jsonSuccess(data, status, headers)` and `jsonError(error, status, headers)`.
  - `@/shared/errors/index.ts`: `AppError`, `BadRequestError`, `UnauthorizedError`, `ForbiddenError`, `NotFoundError`, `ConflictError`.
  - `@/lib/cors.ts`: `getCorsHeaders(request)` and `handleOptions(request)`.
  - `@/lib/parentAuth.ts`: `requireParent(request, env)` supporting Better Auth cookies, legacy `kidstube_parent_session` cookies, and paired device Bearer tokens.
- **Flutter Mobile Widgets & Services (`apps/mobile/lib/`):**
  - `providers/app_provider.dart`: `AppProvider` central state manager.
  - `services/database_service.dart`: `DatabaseService` singleton for SQLite CRUD, guarded pruning, and local watch analytics.
  - `services/download_service.dart`: `DownloadService` queue with HTTP Range resume and orphan file cleanup.
  - `services/vps_api_service.dart`: `VpsApiService` Dio client.
  - `widgets/video_card.dart`, `widgets/video_tile.dart`, `widgets/touch_lock_overlay.dart`, `widgets/child_avatar.dart`, `widgets/kid_embed_player.dart`, `widgets/ambient_blur_background.dart`.

---

## 5. Development Standards & Conventions

### Coding & Architecture Conventions
- **Portal Path Aliasing:** Use `@/*` (mapped to `apps/portal/src/*` in `tsconfig.json`) instead of deep relative imports (`../../../`).
- **Layered Portal Architecture:** Keep Astro API route handlers (`apps/portal/src/pages/api/**`) thin (< 70 lines). Place business logic in `src/features/<domain>/<domain>.service.ts` and database queries in `src/features/<domain>/<domain>.repository.ts` using Drizzle ORM (`src/db/schema/*`).
- **Component Modularity:** Avoid monolithic React or Flutter files. Decompose complex views into focused sub-components under `src/components/<feature>/` and stateful hooks under `src/components/<feature>/hooks/`.
- **Dart / Flutter Standards:** Adhere to `package:flutter_lints/flutter.yaml` (`apps/mobile/analysis_options.yaml`). Maintain zero warnings/errors on `flutter analyze`.

### Visual Design System (`DESIGN.md`)
- **Color Tokens:**
  - Brand Accent: `#FF0000` (`--color-brand`) for play icons, active states, and scrubber bar.
  - Canvas Background: `#FFFFFF` (Light) / `#0F0F0F` (Dark) (`--color-bg-canvas`).
  - Surface Background: `#F2F2F2` (Light) / `#222222` (Dark) (`--color-bg-surface`).
  - Hover Surface: `#E5E5E5` (Light) / `#272727` (Dark) (`--color-bg-hover`).
  - Structural Border: `#E5E5E5` (Light) / `#303030` (Dark) (`--color-border`).
  - Primary Text: `#0F0F0F` (Light) / `#F1F1F1` (Dark) (`--color-text-primary`).
  - Secondary Text: `#606060` (Light) / `#AAAAAA` (Dark) (`--color-text-secondary`).
- **Typography & Layout:**
  - Font family: `Roboto`, `YouTube Sans`, or system sans-serif (`-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`).
  - Video titles must clamp strictly at **2 lines** with ellipsis (`...`).
  - Strict `16:9` aspect ratio (`12px` border radius on cards) for standard videos; `9:16` for Shorts.
  - Category filter pills use full stadium shape (`9999px` / `BorderRadius.circular(20)`).

### Testing & Verification Procedures
- **Flutter Mobile (`apps/mobile`):**
  - Static analysis: `cd apps/mobile && flutter analyze`
  - Unit & widget test suite (20 test files in `apps/mobile/test/`): `make test` or `cd apps/mobile && flutter test`
- **Web Portal (`apps/portal`):**
  - Type checking: `cd apps/portal && pnpm typecheck` (`tsc --noEmit`)
  - Production SSR build verification: `make portal-build` or `cd apps/portal && pnpm build`
- **Native Android (`apps/mobile-android`):**
  - Unit tests: `cd apps/mobile-android && ./gradlew testDebugUnitTest`
- **VPS Server (`apps/server`):**
  - Auth & cleanup tests: `python3 apps/server/test_cleanup_auth.py`

---

## 6. Project-Specific Requirements, Constraints & Non-Negotiables

### Prohibited UI/UX Anti-Patterns (`DESIGN.md` Section 4)
1. **No Generic AI Visual Clutter:** No multi-color gradient text, no neon borders, no heavy glassmorphism backdrop blurs, and no dramatic drop shadows on video feeds.
2. **No Algorithmic Noise:** Never add uncurated recommendation sidebars, external video rabbit holes, comments sections, or live chats.
3. **No Social Triggers:** No dislike counters, no share-to-social popups, no public download buttons for children, and no donate/subscribe prompts.
4. **No Deep Overflow Menus:** Avoid 3-dot overflow menus loaded with complex options in child-facing views.

### Critical Technical & Security Constraints (`PARITY-ANDROID.md` & `docs/`)
1. **Catalog JSON Response Key:** `GET /api/v1/catalog` returns videos under the `all_videos` key (and grouped `sections`), **NOT** a top-level `videos` key. Clients and parsers must read `all_videos`.
2. **Shorts vs. Landscape Routing Integrity:** Never classify a standard `watch?v=` URL or a video with `duration > 70` seconds as a Short, even if `category_id` is `'shorts'`.
3. **Guarded Catalog Pruning:** Mobile clients must **never** wipe or prune local SQLite/downloaded media when `/api/v1/catalog` returns an empty list or network error (`catalog_sync_safeguard_test.dart`, `real_prune_database_service_test.dart`). Pruning >50% of the catalog requires explicit confirmation.
4. **Salted SHA-256 PIN & No Skip-Pairing Backdoor:**
   - Child Gate PINs on mobile must be stored as salted SHA-256 hashes (16-byte random salt in `flutter_secure_storage` / `EncryptedSharedPreferences`), never plaintext.
   - If the default PIN (`1234`) is active, prompt/force the parent to update it.
   - Fresh mobile installs must complete the 6-digit pairing flow (no bypass backdoor).
5. **WebView Lockdown:** Embedded YouTube fallback players must restrict navigation strictly to `youtube-nocookie.com` and `about:blank`, blocking external links, channel navigation, and context menus (`embed_player_escape_test.dart`).
6. **Cloudflare Free-Tier & 1 GB VPS Protection:**
   - Do not send high-frequency network telemetry during video playback; buffer watch events locally in SQLite and sync in batches.
   - Do not add heavy background daemons or memory-intensive services to `apps/server/docker-compose.yml` (VPS has 1 GB RAM / 1 vCPU).
7. **Media Filename Convention:** Hosted MP4s and WebP thumbnails on the VPS must be named `<youtube_id>.mp4` and `<youtube_id>.webp`.

---

## 7. Known Gaps, Assumptions & Items Needing Verification

### Confirmed Facts vs. Historical Doc Discrepancies
- **Confirmed Fact:** `docs/architecture.md` and `docs/monorepo-structure-plan.md` contain historical references to a FastAPI backend on the VPS (`server/backend`), whereas the actual repository (`apps/portal/`, `apps/server/docker-compose.yml`, `docs/api-reference.md`, `docs/vps-optimization-1gb.md`) has fully migrated the REST API and SQLite database to **Cloudflare Workers + Cloudflare D1 + Drizzle ORM** (`apps/portal`), leaving only `nginx:alpine` and `cleanup_service.py` on the VPS.
- **Confirmed Fact:** `apps/mobile-android/PARITY-ANDROID.md` and `TECH-NOTES.md` compare against a React Native implementation (`apps/mobile-rn/`), which is **not** present in the `apps/` directory of this repository (only `apps/mobile`, `apps/mobile-android`, `apps/portal`, and `apps/server` exist in `apps/`).

### Unknown / Needs Verification
- **CI/CD Pipeline Configuration:** `Unknown` / `Needs verification` — No `.github/workflows/` directory was found in the repository root; deployment currently uses `make portal-deploy` (`wrangler deploy`), `make mobile-apk` (`./scripts/build-apk.sh`), and `./scripts/sync-mykidstube.sh`.
- **Production Environment Secrets:** `Needs verification` — Exact production values for `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`, and `CLEANUP_SECRET` are managed externally via Cloudflare Worker secrets / `.env` files (`.env` files are gitignored).
- **Automated End-to-End Browser Tests (Playwright/Cypress):** `Unknown` — `apps/portal` currently verifies via `tsc --noEmit` and `astro build`; no E2E browser test runner is configured in `apps/portal/package.json`.

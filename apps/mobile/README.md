# 📱 MyKidsTube Mobile (Flutter)

<p align="center">
  <strong>A distraction-free, ad-free YouTube player and video sanctuary designed specifically for kids and toddlers.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen" alt="Platform">
  <img src="https://img.shields.io/badge/Mode-100%25%20Standalone%20or%20VPS-orange" alt="Operating Modes">
  <img src="https://img.shields.io/badge/Tests-124%20Passing-success" alt="Tests">
</p>

---

## 🌟 Overview

The **MyKidsTube Mobile App** is a distraction-free, child-proof video player built with Flutter for tablets and smartphones. Mainstream video platforms surround children with recommended rabbit holes, comments, external links, and aggressive autoplay loops. MyKidsTube gives parents 100% control over the library in a clean, authentic YouTube-style dark interface that kids love and parents trust.

---

## 🚀 Key Highlights & Operating Modes

### 1. 100% Standalone Mode (Zero Server / Zero VPS Required)
- **Instant Out-of-the-Box Use:** Download the app, open it, and immediately watch videos. No VPS configuration, no cloud database setup, and no developer tools required.
- **In-App YouTube Video Addition:** Parents can paste any YouTube URL (standard watch video, vertical Short, or playlist). The app automatically fetches channel name, duration, and thumbnail via YouTube OEMBED API and inserts it into the local SQLite catalog.
- **Embedded Sandbox Playback:** Uses sandboxed WebViews configured with privacy parameters (`modestbranding=1`, `rel=0`, `controls=0/1`, `playsinline=1`) to prevent external clickouts, comment sections, or recommendation escapes.

### 2. Curated 60-Video Starter Pack
- **Never Starts from Scratch:** When opening the app for the first time, parents are greeted with a welcome modal offering to load a starter pack of **60 hand-picked, kid-safe videos**:
  - **30 Long-Form Videos:** Cartoons (Peppa Pig, Blippi), Fun Learning & Phonics (ABC songs, counting), Songs (Baby Shark, Wheels on the Bus, Johny Johny), Animals & Nature, and Bedtime Stories.
  - **30 Authentic 9:16 Vertical Shorts & Reels:** Rapid nursery rhymes, animal puzzles, and toddler riddles.
- **Always Accessible:** Can be loaded or reloaded anytime from the **Parent Command Center** or the Kid Home profile menu.
- **Tombstone Resiliency:** Includes an option to *"Restore previously deleted starter videos"* without wiping custom additions.

### 3. Persistent Deletion Guarantee (Tombstones)
- Deleting videos marks their unique identifiers in a dedicated SQLite `deleted_videos` table.
- **Resurrection Prevention:** When pulling down to refresh or syncing the catalog, previously deleted videos are guaranteed to **stay deleted** and are never resurrected.
- Parents can still explicitly re-add any video if they choose.

### 4. Authentic YouTube Dark Design System
- **Theme Tokens:** True YouTube Dark background (`#0F0F0F`), Card Surface (`#212121`), Border dividers (`#303030`), and YouTube Red (`#FF0000`).
- **Clean Video Player:**
  - Removed clunky left sidebar in favor of a sleek, floating right action rail.
  - Title overlay neatly repositioned to the bottom on wide videos.
  - Shorts titles removed to maximize visual immersion for toddlers.
  - Direct orientation toggle button on long-form videos to lock landscape mode on phones or tablets.
- **Responsive Layout:** Adaptive single-column feed on phone portrait, auto-switching to multi-column responsive grids on tablets and landscape orientations.

### 5. Parental Gate & PIN Security
- **Salted SHA-256 PIN Security:** Master PIN stored in encrypted OS storage (`FlutterSecureStorage`) with unique cryptographic salting.
- **Parent Gate Challenge:** Protected by math challenge or master PIN before opening settings or adding videos.
- **Autoplay & Session Limits:** Set maximum daily viewing or session limits (15, 30, 45, 60 min) with gentle bedtime stop screens.
- **Toddler Lock:** Interactive lock button freezes all touchscreen input, system gesture bars, and drawers so babies cannot accidentally exit or skip videos.

### 6. Optional Self-Hosted VPS Mode
- For tech-savvy parents who host private Nginx streaming servers with local MP4 storage, the app seamlessly connects via 6-digit device pairing codes (`KID-482`) to sync remote catalogs, download media for flights, and stream via HTTP 206 byte-ranges.

---

## 📂 Architecture & Directory Structure

```
apps/mobile/
├── assets/
│   └── starter_catalog.json       # 60 bundled offline starter videos & categories
├── lib/
│   ├── main.dart                  # App bootstrap, themes & multi-provider wiring
│   ├── models/
│   │   ├── category_item.dart     # Video category model
│   │   ├── child_profile.dart     # Kid profile with avatar icons
│   │   └── video_item.dart        # Video metadata, embed resolver & short detector
│   ├── providers/
│   │   └── app_provider.dart      # Central state (SQLite, sync, limits, starter catalog)
│   ├── screens/
│   │   ├── kid_home_screen.dart   # Main YouTube feed, filter pills, empty state loader
│   │   ├── kid_player_screen.dart # Fullscreen swipe player with floating action rail
│   │   ├── kid_shorts_feed_screen.dart # Dedicated vertical 9:16 Shorts feed
│   │   ├── parent_dashboard_screen.dart # Parent Command Center & Starter Pack manager
│   │   ├── parent_security_screen.dart  # PIN configuration & salted hash manager
│   │   └── parent_storage_screen.dart   # Offline media & cache maintenance
│   ├── services/
│   │   ├── database_service.dart  # SQLite database, tombstones & batch upserts
│   │   ├── download_service.dart  # Resumable media download manager
│   │   ├── infinite_video_queue.dart # Anti-repetition circular queue
│   │   ├── recommendation_service.dart # Category-balanced shuffle engine
│   │   ├── vps_api_service.dart   # VPS / Cloudflare D1 REST client
│   │   └── youtube_metadata_service.dart # YouTube oEmbed scraper & URL parser
│   ├── utils/
│   │   ├── constants.dart         # YouTube design system color tokens & styles
│   │   └── format_utils.dart      # Duration, timestamp & size formatting
│   └── widgets/
│       ├── add_video_sheet.dart   # Modal sheet to paste YouTube URLs
│       ├── kid_embed_player.dart  # Sandboxed WebView YouTube embed player
│       ├── touch_lock_overlay.dart# Toddler lock overlay
│       └── video_card.dart        # Authentic YouTube card with badge & channel avatar
├── test/                          # 124 comprehensive unit, widget & integration tests
└── pubspec.yaml                   # Flutter dependencies, version & assets
```

---

## 🛠️ Getting Started

### Prerequisites
- **Flutter SDK:** 3.47+ (Dart 3.6+)
- **Android Studio / Xcode:** For device emulation or physical deployment

### Run Debug Mode
```bash
cd apps/mobile
flutter pub get
flutter run
```

### Run All Tests
```bash
flutter test
```
The mobile test suite runs 124 unit and widget tests across catalog persistence, tombstone deletions, PIN security, geometry, and embed safety.

### Build Production Release APKs
```bash
# Build universal APK
flutter build apk --release

# Build split-per-ABI APKs (smaller file size for arm64-v8a, armeabi-v7a, x86_64)
flutter build apk --split-per-abi --release
```
Output binaries are generated in `build/app/outputs/flutter-apk/`.

---

## 📄 License
This mobile client is released under the **MIT License**.

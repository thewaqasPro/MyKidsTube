# 📱 MyKidsTube Mobile (Flutter)

<p align="center">
  <strong>A distraction-free, ad-free YouTube player and video sanctuary designed specifically for kids and toddlers.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Release-v1.3.0-red?logo=github" alt="Release">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen" alt="Platform">
  <img src="https://img.shields.io/badge/Mode-100%25%20Standalone%20or%20VPS-orange" alt="Operating Modes">
  <img src="https://img.shields.io/badge/Tests-128%20Passing-success" alt="Tests">
</p>

---

## 🌟 Overview

The **MyKidsTube Mobile App** is a distraction-free, child-proof video player built with Flutter for tablets and smartphones. Mainstream video platforms surround children with recommended rabbit holes, comments, external links, and aggressive autoplay loops. MyKidsTube gives parents 100% control over the library in a clean, authentic YouTube-style dark interface that kids love and parents trust.

---

## 🚀 Key Highlights & Operating Modes

### 1. In-App YouTube Channel & Keyword Discovery (Zero API Key)
- **Built-in Safe YouTube Explorer:** Parents can search YouTube directly inside the app without opening a separate browser or copying/pasting links.
- **Search by Channel:** Type `@peppapig`, `@CoComelon`, `Ms Rachel`, or `Numberblocks`. The app resolves channel avatars and metadata, displaying all uploaded videos chronologically.
- **Search by Topic:** Search keywords (e.g. *"learning colors"*, *"dinosaur rhymes"*) to find relevant kid videos.
- **1-Tap Instant Add:** Each search result has a `+ Add` button that instantly stores the video into local SQLite and updates to a green `✓ Added` badge.
- **Batch Multi-Select Import:** Select multiple videos (or tap *"Select All"*) and import 10, 20, or 30 videos into a designated category in a single transaction.
- **Zero Quota / No Google Cloud Billing:** Operates completely client-side using `youtube_explode_dart` without requiring any developer API keys.

### 2. Standard Android Material 3 Multi-Tab Parent Center
- Redesigned into a clean, modern Android settings interface with a bottom `NavigationBar`:
  - 🏠 **Overview:** High-level executive statistics (total videos, categories, today's watch time), the **Search YouTube** hero card, single link ingestion, Media Library manager, PIN controls, Curated Starter Pack, and *Return to Kids*.
  - 🔍 **Search YouTube:** Fullscreen channel explorer and keyword discovery engine.
  - ⏱️ **Screen Time:** Daily watch minutes, Autoplay toggle, continuous session limit dropdown (15m, 30m, 45m, 60m, Unlimited), and detailed analytics.
  - ⚙️ **Settings & Device:** Security PIN updates, device cache/storage maintenance, optional collapsible VPS Server settings, and open-source licensing.
- **Refined Material Design:** Eliminated harsh red background cards in favor of dark surface elevation (`#121212`, `#1E1E1E`), clean white contrast typography, and subtle YouTube red accents.

### 3. Clean Distraction-Free Kid Feed
- Removed confusing download arrow icons from the kid's home screen and video cards.
- Cards display strictly high-res thumbnails, clean duration pills, and legible titles/channel names.

### 4. 100% Standalone Mode (Zero Server / Zero VPS Required)
- **Instant Out-of-the-Box Use:** Download the app, open it, and immediately watch videos. No VPS configuration, no cloud database setup, and no developer tools required.
- **Embedded Sandbox Playback:** Uses sandboxed WebViews configured with privacy parameters (`modestbranding=1`, `rel=0`, `controls=0/1`, `playsinline=1`) to prevent external clickouts, comment sections, or recommendation escapes.

### 5. Curated 60-Video Starter Pack
- **Never Starts from Scratch:** When opening the app for the first time, parents are greeted with a welcome modal offering to load a starter pack of **60 hand-picked, kid-safe videos**:
  - **30 Long-Form Videos:** Cartoons (Peppa Pig, Blippi), Fun Learning & Phonics (ABC songs, counting), Songs (Baby Shark, Wheels on the Bus, Johny Johny), Animals & Nature, and Bedtime Stories.
  - **30 Authentic 9:16 Vertical Shorts & Reels:** Rapid nursery rhymes, animal puzzles, and toddler riddles.
- **Always Accessible:** Can be reloaded anytime from the **Parent Command Center** or Kid Home profile menu.
- **Tombstone Resiliency:** Includes an option to *"Restore previously deleted starter videos"* without wiping custom additions.

### 6. Persistent Deletion Guarantee (Tombstones)
- Deleting videos marks their unique identifiers in a dedicated SQLite `deleted_videos` table.
- **Resurrection Prevention:** When pulling down to refresh or syncing the catalog, previously deleted videos are guaranteed to **stay deleted** and are never resurrected.

### 7. Authentic YouTube Dark Design System
- **Theme Tokens:** True YouTube Dark background (`#0F0F0F`), Card Surface (`#212121`), Border dividers (`#303030`), and YouTube Red (`#FF0000`).
- **Clean Video Player:**
  - Floating right action rail for quick likes, orientation, and mute controls.
  - Title overlay neatly repositioned to the bottom on wide videos.
  - Direct orientation toggle button on long-form videos to lock landscape mode on phones or tablets.
- **Responsive Layout:** Adaptive single-column feed on phone portrait, auto-switching to multi-column responsive grids on tablets and landscape orientations.

### 8. Parental Gate & PIN Security
- **Salted SHA-256 PIN Security:** Master PIN stored in encrypted OS storage (`FlutterSecureStorage`) with unique cryptographic salting.
- **Parent Gate Challenge:** Protected by math challenge or master PIN before opening settings or adding videos.
- **Toddler Lock:** Interactive lock button freezes all touchscreen input, system gesture bars, and drawers so babies cannot accidentally exit or skip videos.

### 9. Optional Self-Hosted VPS Mode
- For tech-savvy parents who host private Nginx streaming servers with local MP4 storage, the app connects via 6-digit device pairing codes (`KID-482`) to sync remote catalogs, download media for flights, and stream via HTTP 206 byte-ranges.

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
│   │   └── app_provider.dart      # Central state (SQLite, sync, limits, batch adds)
│   ├── screens/
│   │   ├── kid_home_screen.dart   # Main YouTube feed, filter pills, empty state loader
│   │   ├── kid_player_screen.dart # Fullscreen swipe player with floating action rail
│   │   ├── kid_shorts_feed_screen.dart # Dedicated vertical 9:16 Shorts feed
│   │   ├── parent_dashboard_screen.dart # Multi-tab Parent Command Center
│   │   ├── parent_youtube_search_screen.dart # In-app YouTube & channel discovery
│   │   ├── parent_media_library_screen.dart # Curated library browser & bulk pruner
│   │   ├── parent_security_screen.dart  # PIN configuration & salted hash manager
│   │   └── parent_storage_screen.dart   # Offline media & cache maintenance
│   ├── services/
│   │   ├── database_service.dart  # SQLite database, tombstones & batch upserts
│   │   ├── youtube_explorer_service.dart # YouTube channel & keyword search client
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
│       └── video_card.dart        # Authentic YouTube card without distraction icons
├── test/                          # 128 comprehensive unit, widget & integration tests
└── pubspec.yaml                   # Flutter dependencies, version 1.3.0+3 & assets
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

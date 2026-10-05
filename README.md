# KidsTube (SafePlay)

> **A distraction-free, offline-first kids video player backed by a self-hosted Docker media server with automated URL ingestion.**

Kids get a safe, calm, and distraction-free viewing experience with oversized controls and zero algorithmic recommendations. Parents get complete control by pasting links from YouTube, Vimeo, TikTok, or direct MP4 streams—which the VPS automatically downloads and compresses to kid-friendly 720p/480p MP4s.

---

## Architecture Overview

```
                      [ PARENT LINK INGESTION ]
                (Web Dashboard or Mobile Parent Mode)
                                  │
                                  ▼
┌──────────────────────────────────────────────────────────────────┐
│                   VPS MEDIA SERVER (Docker)                      │
│                                                                  │
│  1. Ingestion Engine (yt-dlp + ffmpeg)                           │
│     - Auto-extracts from YouTube, Vimeo, TikTok, MP4s            │
│     - Normalizes to 720p/480p H.264 MP4 with +faststart          │
│     - Generates WebP thumbnails                                  │
│                                                                  │
│  2. Nginx Reverse Proxy (HTTP 206 Byte-Range Streaming)          │
│                                                                  │
│  3. REST Catalog API & SQLite Database                           │
└─────────────────────────────────┬────────────────────────────────┘
                                  │ (Sync / Direct Download)
                                  ▼
┌──────────────────────────────────────────────────────────────────┐
│                  KIDSTUBE MOBILE APP (Flutter)                   │
│                                                                  │
│  • Offline-First: Checks local storage first (0kb VPS bandwidth) │
│  • Native Video Player: ExoPlayer (Android) & AVPlayer (iOS)     │
│  • Childproof Controls: 3-second Touch Lock & PopScope guard     │
│  • Distraction-Free UI: Large cards, category shelves, no shorts │
│  • Parent Gate: Math challenge or PIN to access settings         │
└──────────────────────────────────────────────────────────────────┘
```

---

## 1. VPS Media Server Setup (Docker)

The complete backend runs in Docker and requires **zero manual video file uploads**.

### Quick Start on your VPS

1. Copy the `server/` directory to your VPS:
   ```bash
   scp -r server user@your-vps-ip:/opt/kidstube
   ```

2. Start the services:
   ```bash
   cd /opt/kidstube
   docker-compose up -d --build
   ```

3. Open the **Parent Web Dashboard**:
   ```
   http://YOUR_VPS_IP:8080/
   ```

4. Paste any video URL (YouTube, Vimeo, TikTok, Dailymotion, or direct MP4), select a category, and click **"Download to Media Server"**.

---

## 2. Mobile App Setup (Android / iOS)

The mobile client is built using Flutter and connects to your VPS media server.

### Prerequisites
- Flutter SDK (3.27+)
- Android Studio / Android SDK (for Android APK build)
- Xcode (for iOS build)

### Running Locally
```bash
# Get dependencies
flutter pub get

# Run on Android device / emulator
flutter run
```

### Connecting App to your VPS
1. Open the app on your Android device or emulator.
2. Tap the **Shield / Parent Lock** icon in the top right.
3. Solve the quick math challenge (or enter PIN `1234`).
4. In **Server Base URL**, enter your VPS address:
   - For Android Emulator: `http://10.0.2.2:8080`
   - For Physical Device: `http://YOUR_VPS_IP:8080`
5. Tap **Save & Test**, then tap **Sync Catalog**.

### Building Release Android APK
```bash
flutter build apk --release
```
The installable APK will be output at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## Key Features

- **Automated URL Ingestion:** No downloading to your PC and re-uploading. Just paste the link.
- **Moderate Quality Preset:** 720p/480p compression saves 70%+ disk space on both VPS and mobile devices (~70-90MB per 10min video).
- **Zero VPS Bandwidth on Downloaded Content:** Downloaded videos play directly from the local device filesystem.
- **Touch Lock Overlay:** Toddlers can hold the tablet without accidentally pausing, seeking, or exiting. Unlocks only after holding for 3 seconds.
- **Accidental Navigation Guard:** `PopScope` blocks accidental back-swipe gestures.
- **Airplane / Car Trip Ready:** Dedicated "Offline Only" switch and pinned "Downloaded & Ready to Watch" shelf.

---

## License

MIT License. Designed with care for parents who want a calm, controlled, and distraction-free viewing experience for their children.

# KidsTube (Monorepo)

> **A distraction-free, offline-first kids video player backed by a self-hosted Docker media server with automated URL ingestion and multi-user device pairing.**

---

## Monorepo Structure

```
MyKidsTube/
├── apps/
│   ├── mobile/                # Native Flutter Application (Android & iOS)
│   │   ├── android/           # Native Android runner & Gradle
│   │   ├── ios/               # Native iOS runner & Xcode project
│   │   ├── lib/               # Dart source code (screens, services, models)
│   │   └── pubspec.yaml       # Flutter dependencies & metadata
│   └── server/                # Self-Hosted VPS Media Server
│       ├── backend/           # FastAPI service (yt-dlp + ffmpeg ingestion)
│       ├── nginx/             # Nginx reverse proxy (HTTP 206 byte-range streaming)
│       └── docker-compose.yml # Server container stack definition
├── docs/                      # Comprehensive technical documentation
│   ├── architecture.md        # System design & Mermaid diagrams
│   ├── api-reference.md       # REST API endpoint specification
│   ├── multi-user-pairing.md  # Multi-device onboarding guide
│   └── monorepo-structure-plan.md
├── scripts/                   # Development helper scripts
│   ├── dev-server.sh          # Quick-launch Docker media server
│   ├── run-mobile.sh          # Run Flutter app
│   └── build-apk.sh           # Generate release APK
├── Makefile                   # Unified developer command palette
├── docker-compose.yml         # Root Docker orchestrator
├── kidstube.code-workspace    # VS Code multi-root workspace file
└── README.md
```

---

## Quick Start (Developer Commands)

We provide a root `Makefile` so you don't need to manually `cd` into subfolders:

```bash
# 1. Start the Docker media server (Nginx + FastAPI + Ingestion Engine)
make server

# 2. View live server logs
make server-logs

# 3. Stop the media server
make server-down

# 4. Run the mobile Flutter app (auto-detects connected phone or emulator)
make mobile

# 5. Build signed release Android APK
make mobile-apk

# 6. Run mobile unit and widget tests
make test
```

---

## 1. VPS Media Server Setup (`apps/server`)

The server is self-contained in Docker and features **automated URL ingestion**:

1. Start the server:
   ```bash
   make server
   ```
2. Open the **Parent Web Dashboard** in your browser:
   ```
   http://localhost:8080/
   ```
3. Paste any video link (YouTube, Vimeo, TikTok, Dailymotion, or direct MP4). The server downloads, transcodes to 720p/480p MP4, and generates WebP thumbnails automatically.

---

## 2. Kids Mobile App Setup (`apps/mobile`)

The mobile client is built using Flutter and ExoPlayer/AVPlayer.

### Running in VS Code
Open the project using the workspace file:
```bash
code kidstube.code-workspace
```
Select **KidsTube Mobile (Debug)** from the Run & Debug tab and press **F5**.

### Connecting to Server
1. When opening the app for the first time on a new phone, it displays a **6-Digit Pairing Code** (e.g. `KID-482`).
2. On your Parent Dashboard (`http://YOUR_VPS_IP:8080/`), go to **Pair Devices**, enter the code, and select which child's profile (e.g. *Maya*, *Noah*, or *Shared*) gets this phone.
3. The phone unlocks immediately into that child's curated library!

---

## Complete Documentation Index

For in-depth guides, visit the **[docs/](docs/)** folder:
- **[Architecture & Diagrams](docs/architecture.md)**
- **[REST API Reference](docs/api-reference.md)**
- **[Multi-User & 5-Kids Pairing Guide](docs/multi-user-pairing.md)**
- **[Monorepo Architecture Plan](docs/monorepo-structure-plan.md)**
- **[Media Ingestion & Video ID Renaming Guide](docs/media-sync-and-renaming.md)**

---

## License

MIT License. Designed with care for parents who want a calm, controlled, and distraction-free viewing experience for their children.

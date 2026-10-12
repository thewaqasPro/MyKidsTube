# KidsTube (Monorepo)

> **A distraction-free, offline-first kids video player backed by a self-hosted Docker media server with automated URL ingestion and multi-user device pairing.**

---

## Monorepo Structure

```
MyKidsTube/
├── apps/
│   ├── mobile/                # Cross-platform Mobile App (Flutter for iOS & Android)
│   │   ├── android/           # Native Android runner & Gradle
│   │   ├── ios/               # Native iOS runner & Xcode project
│   │   ├── lib/               # Dart source code (screens, services, models)
│   │   └── pubspec.yaml       # Flutter dependencies & metadata
│   ├── mobile-android/        # Native Android App (Kotlin + Jetpack Compose)
│   ├── portal/                # Parent Web Portal & API (Astro SSR + Cloudflare Workers)
│   │   ├── migrations/        # D1 SQL schema migrations (Drizzle ORM)
│   │   ├── seeds/             # D1 database setup & seed SQL (d1_ready.sql, d1_clean.sql)
│   │   ├── src/               # React components, Astro pages, and API routes
│   │   └── wrangler.json      # Cloudflare D1 and R2 configuration
│   └── server/                # Self-Hosted VPS Media Streamer
│       ├── nginx/             # Nginx reverse proxy (HTTP 206 byte-range streaming)
│       ├── cleanup_service.py # Storage management and disk maintenance service
│       └── docker-compose.yml # Server container stack definition
├── docs/                      # Comprehensive technical documentation & architecture
├── scripts/                   # Operations & automation scripts (VPS sync, APK builds, D1 tools)
├── Makefile                   # Unified developer command palette
├── docker-compose.yml         # Root Docker orchestrator
├── kidstube.code-workspace    # VS Code multi-root workspace file
└── README.md
```

---

## Quick Start (Developer Commands)

We provide a root `Makefile` so you don't need to manually `cd` into subfolders:

```bash
# 1. Start the Parent Web Portal locally (Astro SSR)
make portal

# 2. Start the Docker media streamer (Nginx + Cleanup Service)
make server

# 3. View live server logs
make server-logs

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
- **[Project-Aware AI Prompt Generator Guide](docs/ai-prompt-generator.md)**

---

## 3. Project-Aware AI Prompt Generator (`ai-prompt-generator.html`)

This repository includes a standalone, zero-dependency HTML prompt generator ([`ai-prompt-generator.html`](ai-prompt-generator.html)) paired with a structured source-of-truth context document ([`AI_PROJECT_CONTEXT.md`](AI_PROJECT_CONTEXT.md)).

### Quick Usage
1. Open [`ai-prompt-generator.html`](ai-prompt-generator.html) directly in any browser (`open ai-prompt-generator.html`) — no build step, backend server, or API key required.
2. Paste a raw voice transcript, bug report, or feature idea into **Section 1** (or click one of the **Ex A–D** preset buttons).
3. Select the **Task Type** (defaults to `Automatic detection`) and **Target AI Agent** (`Generic AI agent`, `ChatGPT`, `Claude / Claude Code`, `Cursor`, `Windsurf`, `GitHub Copilot`, or `Custom agent`).
4. Click **Generate Prompt** to produce a portable, 12-section specification complete with verified MyKidsTube architecture, `DESIGN.md` tokens, and non-negotiable constraints, then click **Copy Prompt** or **Export .md / .txt**.

For instructions on updating [`AI_PROJECT_CONTEXT.md`](AI_PROJECT_CONTEXT.md), enabling **Mode B (AI-Enhanced Backend Proxy / Integrately Webhook)**, and reviewing security/browser considerations, see **[docs/ai-prompt-generator.md](docs/ai-prompt-generator.md)**.

---

## License

MIT License. Designed with care for parents who want a calm, controlled, and distraction-free viewing experience for their children.

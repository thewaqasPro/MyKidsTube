# Project Structure Analysis & Monorepo Plan

This document evaluates the codebase layout and answers whether we should transition to a **pure Monorepo structure**.

---

## 1. Current State vs. Clean Monorepo

### Current Structure (Hybrid Layout)
```
MyKidsTube/
├── android/          # Flutter Android native runner
├── ios/              # Flutter iOS native runner
├── lib/              # Flutter Dart code (Screens, Services, Models)
├── pubspec.yaml      # Flutter package manifest
├── server/           # Backend (Docker Compose, Nginx, FastAPI, static web)
├── docs/             # Documentation & architecture guides
└── test/             # Flutter unit & widget tests
```

### Proposed Pure Monorepo Structure
```
MyKidsTube/
├── apps/
│   ├── mobile/             # Entire Flutter Application
│   │   ├── android/
│   │   ├── ios/
│   │   ├── lib/
│   │   ├── pubspec.yaml
│   │   └── test/
│   └── server/             # Dockerized Media Server
│       ├── backend/
│       ├── nginx/
│       └── docker-compose.yml
├── docs/                   # Complete architecture, API, and setup documentation
├── scripts/                # Development & deployment helper scripts
│   ├── dev-server.sh
│   └── build-apk.sh
├── Makefile                # Unified CLI commands for server & mobile
└── README.md
```

---

## 2. Monorepo Trade-Off Analysis

| Criteria | Current Hybrid Layout | Pure Monorepo (`apps/mobile` + `apps/server`) |
| :--- | :--- | :--- |
| **Separation of Concerns** | Mixed: Flutter root directory shares space with `server/`. | **Clean:** Clear boundary between Python/Docker and Flutter/Dart. |
| **IDE & Tooling** | Opening workspace in VS Code analyzes Flutter immediately. | Needs `.code-workspace` or opening `apps/mobile` directly for Flutter DevTools. |
| **CI / CD Pipelines** | GitHub Actions must use path filtering to avoid rebuilding Docker on Dart changes. | **Optimal:** GitHub Actions naturally maps `apps/mobile/**` to mobile builds and `apps/server/**` to Docker registry tags. |
| **Command Execution** | Run `flutter run` directly from project root. | Run `cd apps/mobile && flutter run` (or use root `Makefile`). |
| **Docker Build Context** | Simple: Docker build runs inside `server/`. | Identical: Docker runs inside `apps/server/`. |

---

## 3. Recommendation

### Should we make it a Monorepo?
**Yes, moving to the `apps/mobile` + `apps/server` layout is recommended if you plan to:**
1. Add a separate Web frontend (e.g. Next.js / React) in the future.
2. Set up automated GitHub Actions CI/CD to build Docker images and release APKs independently.
3. Keep server developers and mobile developers working in clean, isolated folders.

### When to keep the Current Hybrid Layout?
If you are the sole developer and value the convenience of running `flutter run` and `flutter test` directly in the project root without navigating into subfolders, the current structure is already functional and well-segregated.

---

## 4. Migration Steps (If Monorepo is Chosen)

1. Create `apps/mobile` and move:
   - `android/`, `ios/`, `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`
2. Move `server/` to `apps/server/`.
3. Create a root `Makefile`:
   ```makefile
   server-up:
   	cd apps/server && docker compose up -d

   server-logs:
   	cd apps/server && docker compose logs -f

   mobile-run:
   	cd apps/mobile && flutter run

   mobile-apk:
   	cd apps/mobile && flutter build apk --release
   ```
4. Update `.vscode/launch.json` and `.vscode/settings.json` with the new paths.

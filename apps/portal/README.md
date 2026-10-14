# 🌐 MyKidsTube Parental Cloud Portal & Edge API

<p align="center">
  <strong>Edge-rendered web portal and REST API built with Astro 5, React 19, Cloudflare D1 (SQLite), and Cloudflare Workers.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Astro-5.0+-FF5D01?logo=astro&logoColor=white" alt="Astro">
  <img src="https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black" alt="React">
  <img src="https://img.shields.io/badge/Cloudflare-D1%20%7C%20Workers-F38020?logo=cloudflare&logoColor=white" alt="Cloudflare Workers">
  <img src="https://img.shields.io/badge/ORM-Drizzle-C5F74F?logo=drizzle&logoColor=black" alt="Drizzle ORM">
</p>

---

## 🌟 Overview

The **MyKidsTube Portal** serves as the central management plane for families utilizing the optional cloud/VPS sync ecosystem. It provides:
1. **Parent Studio Dashboard:** A sleek, responsive web interface for curating videos, tagging age categories, managing child profiles, and viewing aggregate watch analytics.
2. **Edge REST API:** Cloudflare Workers endpoints consumed by the mobile apps for 6-digit device activation codes (`/api/v1/devices/register`), catalog synchronization (`/api/v1/catalog`), and watch event telemetry (`/api/metrics/watch`).
3. **Ingestion Queue:** Ingest new YouTube video URLs or full playlists into Cloudflare D1 for subsequent desktop optimization and media streaming.

---

## 📂 Architecture & Directory Structure

```
apps/portal/
├── migrations/                # Drizzle D1 SQL migration scripts
│   ├── 0001_admin_settings.sql
│   ├── 0002_watch_events.sql
│   └── 0003_parent_sessions.sql
├── seeds/                     # Database bootstrap & demo seed data
│   ├── d1_ready.sql           # Complete catalog bootstrap with 100 sample items
│   └── d1_clean.sql
├── src/
│   ├── components/            # React 19 dashboard & UI components
│   │   ├── AnalyticsChart.tsx # Screen time graphs & watch stats
│   │   ├── VideoCard.tsx      # Video curation & management cards
│   │   └── DeviceModal.tsx    # 6-digit pairing code generator
│   ├── db/                    # Drizzle ORM schemas (videos, profiles, devices)
│   ├── layouts/               # Master HTML layouts
│   ├── lib/                   # Auth & D1 database helpers
│   └── pages/
│       ├── index.astro        # Public landing & studio dashboard
│       └── api/               # Cloudflare Workers REST API routes
│           ├── v1/catalog.ts  # Curated catalog retrieval
│           ├── v1/devices/    # 6-digit device registration & status polling
│           ├── v1/ingest.ts   # Video ingestion queue
│           └── metrics/watch.ts # Watch session telemetry
├── drizzle.config.ts          # Drizzle ORM configuration
├── wrangler.json              # Cloudflare Workers, D1 & R2 configuration
└── package.json               # Node dependencies
```

---

## 🛠️ Local Development

### 1. Prerequisites
- **Node.js:** 20+
- **pnpm:** `npm install -g pnpm`
- **Wrangler CLI:** `pnpm install -g wrangler`

### 2. Setup & Run
```bash
cd apps/portal

# Install dependencies
pnpm install

# Copy environment variables
cp .env.example .env

# Apply D1 migrations to local SQLite
npx wrangler d1 migrations apply mykidstube --local

# (Optional) Seed initial demo catalog
npx wrangler d1 execute mykidstube --local --file=seeds/d1_ready.sql

# Start development server
pnpm dev
```
Open **`http://localhost:4321`** in your browser.

---

## 📡 REST API Reference

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/v1/health` | `GET` | Health check and server status |
| `/api/v1/catalog?profile_id={id}` | `GET` | Returns categorized video list and sections |
| `/api/v1/devices/register` | `POST` | Registers a device and generates a 6-digit pairing code |
| `/api/v1/devices/status/{code}` | `GET` | Polls activation status and returns device auth token |
| `/api/v1/profiles` | `GET` | Fetches available child profiles |
| `/api/v1/ingest` | `POST` | Enqueues a video or playlist URL for processing |
| `/api/metrics/watch` | `POST` | Ingests sanitized watch duration and completion telemetry |

---

## 🚀 Cloudflare Deployment

Deploy directly to Cloudflare Workers with D1 bindings:
```bash
# Deploy to Cloudflare Workers
pnpm build
npx wrangler deploy

# Apply migrations on production D1
npx wrangler d1 migrations apply mykidstube --remote
```

---

## 📄 License
Released under the **MIT License**.

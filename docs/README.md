# KidsTube Documentation

Welcome to the technical documentation for KidsTube.

---

## Documentation Index

1. **[Architecture & Design](architecture.md)**
   - End-to-end system design, dual operating modes (Standalone vs. VPS), Mermaid diagrams, Nginx byte-range streaming, yt-dlp/ffmpeg ingestion, and offline caching mechanics.

2. **[Standalone Mode & Curated Starter Pack](standalone-mode-and-starter-pack.md)**
   - 100% serverless operation, YouTube oEmbed ingestion, sandboxed iframe player, 60-video bundled starter catalog, and persistent tombstone deletion guarantees.

3. **[REST API Reference](api-reference.md)**
   - Complete endpoint documentation for catalog queries, video ingestion, device registration, 6-digit pairing, and child profiles.

4. **[Multi-User & Device Pairing Guide](multi-user-pairing.md)**
   - Step-by-step instructions for managing 5 kids & 5 phones, 6-digit device onboarding, dedicated vs shared tablet modes, and multi-family sharing.

5. **[Monorepo Structure Analysis](monorepo-structure-plan.md)**
   - Review of current hybrid layout vs. clean monorepo (`apps/mobile` + `apps/server`), trade-offs, and migration steps.

6. **[1 GB RAM / 1 Core VPS Optimization Guide](vps-optimization-1gb.md)**
   - OS configuration (2GB swap, swappiness, Docker log rotation), zero-CPU stream remuxing, single-thread queues, and memory constraints.

7. **[Media Ingestion, Video ID Resolution & VPS Sync Guide](media-sync-and-renaming.md)**
   - Automatic YouTube ID matching, bulk video renamer, HandBrake pipeline, and synchronization to self-hosted VPS storage.

8. **[Project-Aware AI Prompt Generator Guide](ai-prompt-generator.md)**
   - How to use `ai-prompt-generator.html`, update `AI_PROJECT_CONTEXT.md`, and integrate Mode B LLM proxies or automation webhooks.

# KidsTube: System Architecture & Design

This document details the complete end-to-end architecture of KidsTube, covering the automated Dockerized VPS Media Server and the native offline-first Flutter mobile client.

---

## 1. High-Level Architecture Diagram

```mermaid
graph TB
    subgraph Parents["Parent Interfaces"]
        WebAdmin["Parent Web Dashboard<br/>(Browser: http://VPS_IP:8080)"]
        MobileGate["Mobile Parent Gate<br/>(Phone PIN/Math Lock)"]
    end

    subgraph VPS["VPS Media Server (Docker Compose)"]
        Nginx["Nginx Reverse Proxy & Media Streamer<br/>- HTTP 206 Partial Content (Byte-Range)<br/>- Fast Seek & Scrubbing<br/>- Static Caching (/media/videos, /media/thumbs)"]
        
        API["FastAPI Backend Server<br/>- Catalog REST API<br/>- Device Pairing Engine<br/>- Profile Management<br/>- Ingestion Queue"]
        
        IngestEngine["Ingestion Engine<br/>- yt-dlp (YouTube + 1000+ sites)<br/>- ffmpeg (720p/480p MP4 +faststart)<br/>- WebP Thumbnail Converter"]
        
        SQLite[("Embedded SQLite DB<br/>data/catalog.db")]
        Storage[("Persistent Media Storage<br/>data/media/videos/*.mp4<br/>data/media/thumbs/*.webp")]
        
        Nginx --> API
        Nginx --> Storage
        API --> IngestEngine
        API --> SQLite
        IngestEngine --> Storage
        IngestEngine --> SQLite
    end

    subgraph Clients["Kids' Mobile Devices (Android & iOS)"]
        Pairing["6-Digit Device Pairing<br/>(KID-482)"]
        SyncEngine["Catalog Sync (Dio Client)"]
        Downloader["Background Download Engine<br/>(Dio + PathProvider)"]
        LocalDB[("Local SQLite DB<br/>kidstube_v2.db")]
        LocalDisk[("Local Storage<br/>Sandboxed Documents Dir")]
        Player["Native Video Player<br/>(video_player / ExoPlayer)"]
        ChildUI["Childproof UI<br/>- 3s Touch Lock<br/>- PopScope Back Interception<br/>- Shelves & Large Tiles"]
    end

    WebAdmin -->|1. Submit URL / Pair Device| API
    MobileGate -->|1. Submit URL / Manage Storage| API
    Pairing -->|2. Register & Poll Status| API
    SyncEngine -->|3. Sync Profile Catalog| API
    SyncEngine -->|4. Store Metadata| LocalDB
    Downloader -->|5. One-Time Download| Nginx
    Downloader -->|6. Save MP4/WebP| LocalDisk
    LocalDisk -->|7. Offline Play (0kb VPS Data)| Player
    Nginx -.->|Fallback Direct Stream| Player
    Player --> ChildUI
```

---

## 2. Core Subsystems

### A. Automated Media Ingestion Engine (`yt-dlp` + `ffmpeg`)
- **Universal Provider Support:** Works with YouTube, Vimeo, Dailymotion, TikTok, and direct `.mp4` URLs.
- **Moderate Quality Profile:** Automatically normalizes uploaded streams to **720p or 480p H.264 (AVC) + AAC audio**.
- **FastStart Optimization:** Uses `-movflags +faststart` to place the MP4 `moov` atom at the beginning of the file, allowing instant playback before the full file is downloaded.
- **Deduplication:** Videos are keyed by their source URL. If two families or multiple profiles add the same video, it is only downloaded and stored on disk **once**.

### B. High-Performance Media Streaming (`Nginx`)
- Implements standard **HTTP 206 Partial Content**.
- Allows mobile players to request specific byte ranges (e.g. `Range: bytes=1048576-2097151`).
- Eliminates server RAM spikes because Nginx uses kernel-level `sendfile` directly from disk to network socket.

### C. Offline-First Mobile Storage
- **Local-First Decision Tree:**
  ```mermaid
  graph LR
      Start[Tap Video] --> Check{Is Local File on Disk?}
      Check -->|Yes| PlayLocal[Play File(localPath)<br/>Zero VPS Network Usage]
      Check -->|No| StreamRemote[Stream NetworkUrl(streamUrl)<br/>Via Nginx Byte-Ranges]
  ```
- **Storage Sandbox:** Downloaded media is stored in `getApplicationDocumentsDirectory()/kidstube_media/`.
- **Management:** Parents can monitor total disk space used and clear cache with a single tap.

### D. Childproof Playback & Navigation
- **Hardware Back Interception (`PopScope`):** Blocks accidental swipe-to-back gestures on Android and iOS.
- **3-Second Touch Lock:** Freezes all controls and touch events. Unlocks only after holding the lock icon for 3 continuous seconds.
- **Distraction-Free Experience:** No comments, no subscribe counts, no likes/dislikes, no recommendation rabbit holes.

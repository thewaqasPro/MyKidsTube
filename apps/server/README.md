# KidsTube VPS Media Server & Ingestion Engine

A production-grade, self-hosted media server and automated video ingestion engine designed for the KidsTube mobile application.

## Features

- **Automated URL Ingestion (`yt-dlp`):** Paste links from YouTube, Vimeo, Dailymotion, TikTok, and direct MP4 streams.
- **Moderate Quality Transcoding (`ffmpeg`):** Compresses videos to kid-optimized 720p/480p H.264 MP4 with `+faststart` (shrinks 10min cartoons to ~70-90MB).
- **HTTP 206 Byte-Range Streaming:** Nginx reverse proxy configured for smooth video scrubbing without high memory usage.
- **Web Admin Dashboard:** Accessible from any browser to submit links, view download progress, and manage the catalog.
- **REST Catalog API:** Exposes `/api/v1/catalog` for the Flutter Android/iOS app to sync and stream/download.

## Deployment on VPS

### Prerequisites
- Docker & Docker Compose installed on your VPS:
  ```bash
  sudo apt update && sudo apt install -y docker.io docker-compose
  ```

### Quick Start

1. Copy the `server/` directory to your VPS:
   ```bash
   scp -r server user@your-vps-ip:/opt/kidstube
   ```

2. Start the service:
   ```bash
   cd /opt/kidstube
   docker-compose up -d --build
   ```

3. Open in your browser:
   ```
   http://YOUR_VPS_IP:8080/
   ```

4. In the KidsTube mobile app:
   Go to Parent Settings -> enter Server URL:
   ```
   http://YOUR_VPS_IP:8080
   ```

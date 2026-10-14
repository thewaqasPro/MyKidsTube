# 🖥️ MyKidsTube VPS Media Streaming Server

<p align="center">
  <strong>Ultra-low footprint, high-concurrency Nginx media streaming service optimized for 1GB VPS hardware.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white" alt="Docker Compose">
  <img src="https://img.shields.io/badge/Nginx-Alpine-009639?logo=nginx&logoColor=white" alt="Nginx Alpine">
  <img src="https://img.shields.io/badge/RAM-<25MB-green" alt="Memory">
  <img src="https://img.shields.io/badge/Protocol-HTTP%20206%20Byte--Range-blue" alt="Protocol">
</p>

---

## 🌟 Overview

The **MyKidsTube Media Server** is a lightweight, zero-overhead static streamer engineered to run flawlessly on low-cost VPS instances (e.g., 1 vCPU, 1 GB RAM, 80 GB SSD). 

It offloads heavy video decoding to client devices while serving optimized MP4 files (`<youtube_id>.mp4`) with instant byte-range seeks, aggressive caching headers, and rate limiting.

---

## 🚀 Key Specifications

- **Memory Consumption:** `< 25 MB RAM` using Nginx Alpine.
- **Streaming Protocol:** HTTP 206 Partial Content (Byte-Range requests for instant scrubbing without full file buffering).
- **Storage Layout:**
  - Videos: `/var/www/media/videos/*.mp4`
  - Thumbnails: `/var/www/media/thumbs/*.webp`
- **Security & Maintenance:** Built-in secret-authenticated cleanup microservice (`cleanup_service.py`) for automatic pruning of deleted media.

---

## 🛠️ Deployment Instructions

### 1. Docker Compose (Recommended)
```bash
cd apps/server

# Copy environment template
cp .env.example .env

# Generate TLS certificates for local domain or IP
../../scripts/make-dev-cert.sh localhost

# Start container in detached mode
docker compose up -d
```

### 2. Native Systemd / Nginx Host
If running directly on Ubuntu/Debian:
```bash
sudo cp nginx/nginx.conf /etc/nginx/sites-available/kidstube.conf
sudo ln -s /etc/nginx/sites-available/kidstube.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

## 📡 Endpoints Exposed

| Path | Protocol | Purpose |
| :--- | :--- | :--- |
| `http://<IP>:8080/health` | HTTP | Health check probe (returns `200 OK`) |
| `http://<IP>:8080/media/videos/{id}.mp4` | HTTP 206 | Byte-range video stream |
| `http://<IP>:8080/media/thumbs/{id}.webp` | HTTP 200 | WebP thumbnail image |
| `https://<IP>:8443/media/...` | HTTPS | Encrypted TLS streaming endpoint |

---

## 📄 License
Released under the **MIT License**.

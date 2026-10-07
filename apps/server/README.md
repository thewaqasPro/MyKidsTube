# KidsTube VPS Media Server (Nginx Static Streamer)

High-performance, ultra-low-footprint static media streaming server for **MyKidsTube** running on Ubuntu VPS (80 GB SSD disk).

## Role in Architecture

- **Role**: Pure static media storage and streaming.
- **Memory Footprint**: < 25 MB RAM (Alpine Nginx).
- **Video Storage**: `/var/www/media/videos/`
- **Thumbnail Storage**: `/var/www/media/thumbs/`
- **Streaming Protocol**: HTTP 206 Partial Content (Byte-Range requests for zero-lag video scrubbing).
- **All Application Logic & APIs**: Hosted entirely in `apps/portal` on Cloudflare Workers + Cloudflare D1.

## Deployment on VPS

Run via Docker Compose:
```bash
cd /opt/kidstube
docker compose up -d
```
Or reload Nginx directly if running on native host:
```bash
sudo nginx -t && sudo nginx -s reload
```

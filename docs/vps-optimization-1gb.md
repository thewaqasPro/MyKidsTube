# VPS Optimization Guide (1 GB RAM & 1 vCPU)

This guide documents the low-footprint architecture and provides the exact OS configuration steps to run **MyKidsTube** reliably on a budget VPS (1 GB RAM, 1 CPU Core) without Out-Of-Memory (OOM) crashes, CPU throttling, or SSH lockups.

---

## 1. Resource Footprint Overview

| Component | Default Footprint | Optimized Footprint | Strategy |
| :--- | :--- | :--- | :--- |
| **Nginx Container** | ~15–30 MB | **~2.5 MB** | 1 worker, reduced client buffers, `sendfile` zero-copy |
| **Backend (FastAPI)** | ~120–180 MB | **~46 MB** | 1 Uvicorn worker, lightweight SQLite WAL mode |
| **`yt-dlp` & `ffmpeg`** | ~400–900 MB (100% CPU) | **< 80 MB (< 5% CPU)** | Stream-copy remuxing (no re-encoding), 1 thread, 1 concurrent download |
| **Host OS Baseline** | ~150–220 MB | ~150–220 MB | Standard Ubuntu/Debian minimal |
| **Total Idle Memory** | ~350 MB | **~200 MB** | **> 800 MB free headroom for disk buffers & downloads** |

---

## 2. Essential VPS Host Configuration (Run Once on Your VPS)

Before launching Docker on a 1 GB VPS, execute these 3 steps via SSH.

### Step 1: Create a 2 GB Swap File (Mandatory)
Almost all cloud VPS providers (Hetzner, DigitalOcean, Linode, Hostinger) ship Linux images with **0 MB swap**. If memory spikes past 950 MB during an active download, the Linux kernel OOM-killer will terminate Docker. A 2 GB swap file guarantees stability.

Run as `root` on your VPS:
```bash
# 1. Allocate 2 GB swap file
fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048

# 2. Set strict permissions
chmod 600 /swapfile

# 3. Format and activate swap
mkswap /swapfile
swapon /swapfile

# 4. Make swap permanent across reboots
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 5. Optimize swappiness (only swap when physical RAM is > 90% full)
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50
echo 'vm.swappiness=10' >> /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf

# 6. Verify swap is active
free -m
```

---

### Step 2: Configure Docker Log Rotation
On a small VPS with a 20–25 GB SSD, Docker container logs can quietly fill up the disk over months.

Create or edit `/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```
Restart Docker to apply:
```bash
systemctl restart docker
```

---

## 3. Application Optimizations Built into MyKidsTube

The codebase has been specifically tuned for 1 vCPU / 1 GB RAM:

### 1. Zero-CPU "Smart Remuxing" Instead of Transcoding
- **The Problem:** Video transcoding (`libx264` re-encoding) maxes out 1 vCPU at 100% for 5–10 minutes per video, consuming 500+ MB RAM.
- **The Solution:** 95%+ of YouTube videos already have pre-encoded H.264 (`avc1`) video and AAC (`m4a`/`mp4a`) audio streams.
- In `apps/server/backend/ingestion.py`:
  - `format` specifically requests `bestvideo[vcodec^=avc1]+bestaudio[acodec^=mp4a]`.
  - `Merger` postprocessor uses `-c:v copy -c:a copy -movflags +faststart`.
  - **Result:** Video ingestion finishes in **2 to 4 seconds**, using **< 5% CPU** and **~25 MB RAM**.
  - If a video format requires conversion (e.g., raw WebM/VP9), it falls back to `-threads 1 -preset ultrafast -crf 26` to prevent CPU lockups.

### 2. Strict Concurrency (`MAX_CONCURRENT_DOWNLOADS=1`)
- Multiple simultaneous video downloads would bottleneck 1 vCPU and fight for I/O.
- Parents can paste 10 links at once in the web dashboard; they are placed in an `asyncio.Queue` and processed sequentially one after another.

### 3. Docker Hard Memory Limits
In `apps/server/docker-compose.yml`:
- `safekids_backend`: `mem_limit: 650m`, `cpus: 0.85`
- `safekids_nginx`: `mem_limit: 64m`, `cpus: 0.15`
This guarantees that Docker can never consume 100% of memory or CPU, keeping SSH responsive and the OS healthy.

### 4. Nginx Zero-Copy Streaming
In `apps/server/nginx/nginx.conf`:
- `worker_processes 1;` (avoids spawning unnecessary worker processes).
- `sendfile on;` and `tcp_nopush on;`: Videos are served directly from Linux kernel page cache to the network socket with **zero memory copies** in user space.
- 5 kids can stream MP4s simultaneously and Nginx uses under **3 MB of RAM**.

### 5. SQLite WAL Mode
In `apps/server/backend/database.py`:
- `PRAGMA journal_mode = WAL;`: Enables concurrent reads while downloads write new records.
- `PRAGMA synchronous = NORMAL;`: Minimizes disk sync operations.
- `PRAGMA cache_size = -2000;`: Limits SQLite cache to ~2 MB RAM.

---

## 4. Storage & Quality Planning

| Video Quality | Avg File Size (10 min) | Videos per 10 GB Disk Space | Recommended For |
| :--- | :--- | :--- | :--- |
| **480p (Default)** | **~35–50 MB** | **~220–280 videos** | Phones & small tablets (Ideal for 1GB VPS) |
| **720p** | **~75–100 MB** | **~100–130 videos** | 10" Tablets & TV screens |

> **Pro Tip:** In `apps/server/docker-compose.yml`, leave `DEFAULT_QUALITY=480p`. Kids cannot tell the difference between 480p and 1080p on a 6-inch phone screen, but 480p uses **50% less VPS disk space** and downloads **2x faster** over Wi-Fi.

---

## 5. Monitoring Your 1 GB VPS

After deploying, verify your resource usage at any time:

```bash
# 1. Check live memory and CPU usage of containers
docker stats --no-stream

# 2. Check system-wide RAM and Swap
free -h

# 3. Check system load average (ideal is under 1.0)
uptime
```

# VPS Optimization Guide (1 GB RAM & 1 vCPU)

This guide documents the architecture and OS configuration for running the **MyKidsTube** media storage and streaming server on a budget VPS (1 GB RAM, 1 CPU Core) without Out-Of-Memory (OOM) crashes, CPU throttling, or SSH lockups.

---

## 1. System Architecture

The MyKidsTube system is divided into two decoupled layers:
1. **API & Metadata Layer (Cloudflare Workers & D1 & R2):**
   - Catalog metadata, child profiles, pairing handshake, parent authentication, and session handling run serverless on Cloudflare Edge.
   - Zero VPS CPU and zero VPS RAM are consumed for API logic or database queries.
2. **Media Storage & Streaming Layer (VPS + Nginx):**
   - The VPS runs an alpine Nginx container dedicated to zero-copy streaming of MP4 video files (`sendfile`, HTTP 206 Partial Content range requests) and static thumbnails.
   - Batch downloading and remuxing is handled either locally via residential IP (`scripts/sync-mykidstube.sh`) or in throttled batch jobs.

---

## 2. Resource Footprint Overview

| Component | Default Footprint | Optimized Footprint | Strategy |
| :--- | :--- | :--- | :--- |
| **Nginx Container** | ~15–30 MB | **~3–5 MB** | 1 worker, reduced client buffers, `sendfile` zero-copy |
| **Edge API & D1** | Cloudflare | **0 MB (Serverless)** | No Python / FastAPI process on VPS |
| **Media Streaming** | 50–100 MB | **< 10 MB** | Kernel-level zero-copy TCP transmission |
| **Host OS Baseline** | ~150–220 MB | ~150–220 MB | Standard Ubuntu/Debian minimal |
| **Total Idle Memory** | ~250 MB | **~180 MB** | **> 800 MB free headroom for disk buffers & downloads** |

---

## 3. Essential VPS Host Configuration (Run Once on Your VPS)

Before launching Docker on a 1 GB VPS, execute these steps via SSH:

### Step 1: Create a 2 GB Swap File (Mandatory)
Almost all cloud VPS providers (Hetzner, DigitalOcean, Linode, Hostinger) ship Linux images with **0 MB swap**. If memory spikes past 950 MB during an active sync, the Linux kernel OOM-killer will terminate Docker. A 2 GB swap file guarantees stability.

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

## 4. Nginx Optimizations in `apps/server/nginx/nginx.conf`

- **Single Worker Process:** `worker_processes 1;` eliminates context switching overhead on single-core VPS.
- **Zero-Copy Streaming:** `sendfile on;` and `tcp_nopush on;` stream files directly from the page cache into network packets with zero userspace memory buffering.
- **Rate & Connection Limiting:** 
  - `limit_req_zone $real_client_ip zone=media_limit:10m rate=10r/s;`
  - `limit_conn_zone $real_client_ip zone=media_conn:10m;`
  - Defends against abusive scraping or range-request floods (503 Service Unavailable when exceeded).
- **Security Headers & Scoped CORS:**
  - `X-Content-Type-Options: nosniff`, `X-Frame-Options: SAMEORIGIN`, `Referrer-Policy: strict-origin-when-cross-origin`.
  - CORS headers restricted to authorized portal and mobile application origins.
- **Health Check & TLS:**
  - Container healthcheck at `/health`.
  - TLS termination on Port 443 with automated self-signed fallback (`scripts/make-dev-cert.sh`) or Certbot production certificates.

---

## 5. Monitoring Your 1 GB VPS

```bash
# 1. Check live memory and CPU usage of containers
docker stats --no-stream

# 2. Check system-wide RAM and Swap
free -h

# 3. Check system load average
uptime
```

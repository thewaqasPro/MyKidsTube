# Media Ingestion, Video ID Resolution & VPS Sync Guide

> **This guide explains how video files are resolved to their YouTube IDs, batch-encoded, and synchronized to the self-hosted VPS media storage.**

---

## 📌 Why Filenames Must Be `<youtube_id>.mp4`

The KidsTube architecture serves media directly over HTTP 206 byte-range streaming via Nginx and the Cloudflare D1 catalog:
- Streaming URL format: `https://kidsapi.waqas.pro/media/videos/{youtube_id}.mp4`
- Thumbnail format: `https://kidsapi.waqas.pro/media/thumbs/{youtube_id}.webp`

When downloading videos with desktop tools (such as *4K Video Downloader*, web browsers, or default HandBrake output presets), files are often saved with human-readable titles (e.g. `Aladdin - A Whole New World.mp4` or `Dwayne Johnson - You're Welcome.mp4`).

To prevent broken streams and manual renaming work, the repository provides automated tools to resolve any video to its 11-character YouTube ID (`<id>.mp4`).

---

## 🚀 How to Use It in the Future

### Approach 1: Automatic Renaming via Playlist URL (Recommended)
When you have downloaded or encoded a batch of videos from a YouTube playlist into `~/Downloads/MyKidsTube_Optimized/`:

```bash
./scripts/sync-mykidstube.sh rename "https://www.youtube.com/playlist?list=PLOba6OKTJnLbDvwBBEwO1EaVsiICn8Svw"
```

**What it does:**
- Queries playlist metadata in bulk (~2 seconds via `yt-dlp`).
- Runs fuzzy title matching (normalizing casing, removing promotional tags like `[High Quality]`, `(Official Video)`, etc.).
- Renames all files to `<youtube_id>.mp4` in place.
- Generates a local `rename_map.json` for full auditability and undo capability.

---

### Approach 2: Automatic Renaming During Upload (One-Shot)
You do not even need to run a separate rename step before uploading. If you have files with song titles in `~/Downloads/MyKidsTube_Optimized/`, pass the playlist URL directly to the upload command:

```bash
./scripts/sync-mykidstube.sh upload "https://www.youtube.com/playlist?list=PLOba6OKTJnLbDvwBBEwO1EaVsiICn8Svw"
```

**What it does:**
1. Scans `~/Downloads/MyKidsTube_Optimized/` for non-ID filenames.
2. If human titles are found, it runs the ID resolver automatically.
3. Rsyncs the files directly to the VPS staging directory.
4. Atomically moves the files to `/home/ubuntu/kidstube/data/media/videos/` (`/var/www/media/videos/`).

---

### Approach 3: When You Have No Playlist URL (Automatic Search)
If you have a folder of videos with arbitrary titles and no playlist link:

```bash
./scripts/sync-mykidstube.sh rename
# OR run the Python utility directly:
./scripts/rename_videos.py --search
```

**What it does:**
- Queries YouTube search (`ytsearch1:<title>`) for each individual video file.
- Compares fuzzy similarity between the local filename and the search result.
- Renames the file to the discovered YouTube ID.

---

### Approach 4: Prevent Title Issues at Download Time
You can download any YouTube playlist or video directly with ID filenames from your Mac terminal:

```bash
./scripts/sync-mykidstube.sh download "https://www.youtube.com/playlist?list=..."
```

**Why this works:**
- Files are saved as `~/Downloads/MyKidsTube_Raw/%(id)s.mp4`.
- When you drop these raw files into HandBrake for 720p web-optimized encoding, HandBrake preserves the input filename, automatically outputting `<youtube_id>.mp4` to `~/Downloads/MyKidsTube_Optimized/`.

---

## 🔄 Safety & Verification Commands

### Preview Without Changing Anything (Dry-Run)
To test how files will be matched without renaming any files on disk:
```bash
./scripts/rename_videos.py --playlist "https://www.youtube.com/playlist?list=..." --dry-run
```

### Undo Previous Renames (Revert to Original Titles)
If you ever need to revert files back to their human-readable song titles:
```bash
./scripts/rename_videos.py --undo
```
*(Uses the local `rename_map.json` created during the rename operation).*

### Verify Files on VPS
To check the count and sample of videos stored on the VPS:
```bash
ssh -i vps/ssh-key-2026-09-27.key ubuntu@155.248.219.73 "ls -1 /home/ubuntu/kidstube/data/media/videos/*.mp4 | wc -l"
```

---

## 📋 Command Reference

### `scripts/sync-mykidstube.sh`
| Command | Arguments | Description |
| :--- | :--- | :--- |
| `export` | None | Export pending links from Cloudflare D1 queue to `RAW_DIR/links.txt`. |
| `download` | `[PLAYLIST_OR_URL]` | Download videos via local connection directly by ID. |
| `rename` | `[PLAYLIST_URL]` | Auto-resolve and rename local files to YouTube IDs. |
| `upload` | `[PLAYLIST_URL]` | Auto-resolves (if needed), uploads to VPS, and auto-syncs Cloudflare D1 catalog. |
| `sync-d1` | `[PLAYLIST_URL]` | Registers local/VPS videos into Cloudflare D1 so they appear in Parent Studio & apps. |
| `status` | None | Query library and queue status from Cloudflare worker API. |
| `prune` | None | Remove orphaned media files from VPS storage not in active catalog. |

### `scripts/rename_videos.py`
| Flag | Description |
| :--- | :--- |
| `folder` | Target directory containing MP4 files (default: `~/Downloads/MyKidsTube_Optimized`). |
| `--playlist`, `-p` | YouTube Playlist or Channel URL for bulk metadata matching. |
| `--links`, `-l` | Path to a text file containing YouTube URLs (e.g. `links.txt`). |
| `--search`, `-s` | Search YouTube for each file title when no playlist URL is available. |
| `--dry-run`, `-n` | Preview matches without modifying any files on disk. |
| `--undo` | Revert renamed files back to their original names using `rename_map.json`. |

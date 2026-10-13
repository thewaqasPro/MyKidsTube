#!/usr/bin/env python3
"""
MyKidsTube — Upload Playlist Videos to VPS
Matches downloaded MP4 files in ~/Downloads/MyKidsTube_Optimized to their
YouTube video IDs from the playlist, and uploads them to the VPS media storage.
"""

import os
import sys
import json
import re
import difflib
import subprocess

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCAL_DIR = os.path.expanduser("~/Downloads/MyKidsTube_Optimized")

# Auto-detect local VPS IP and user from vps/ip.md if available
default_vps_host = "your-vps-ip"
default_vps_user = "ubuntu"
ip_file = os.path.join(REPO_ROOT, "vps", "ip.md")
if os.path.exists(ip_file):
    try:
        with open(ip_file, "r") as f:
            content = f.read().strip()
            if "@" in content:
                default_vps_user, default_vps_host = content.split("@", 1)
            elif content:
                default_vps_host = content
    except Exception:
        pass

# Auto-detect local SSH key from vps/*.key if available
default_ssh_key = os.path.join(REPO_ROOT, "vps", "id_rsa")
vps_dir = os.path.join(REPO_ROOT, "vps")
if os.path.isdir(vps_dir):
    for fname in os.listdir(vps_dir):
        if fname.endswith(".key"):
            default_ssh_key = os.path.join(vps_dir, fname)
            break

PLAYLIST_URL = os.environ.get("PLAYLIST_URL", "")
SSH_KEY = os.environ.get("SSH_KEY", default_ssh_key)
VPS_HOST = os.environ.get("VPS_HOST", default_vps_host)
VPS_USER = os.environ.get("VPS_USER", default_vps_user)
VPS_TARGET_DIR = "/home/ubuntu/kidstube/data/media/videos"
VPS_THUMBS_DIR = "/home/ubuntu/kidstube/data/media/thumbs"

def normalize(s):
    s = re.sub(r'\(.*?\)|\[.*?\]', '', s)
    s = re.sub(r'[^a-zA-Z0-9]', '', s)
    return s.lower()

def main():
    global PLAYLIST_URL
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        PLAYLIST_URL = sys.argv[1]

    if not PLAYLIST_URL:
        print("❌ Usage: python3 upload_playlist_videos.py <PLAYLIST_URL> [--dry-run]")
        sys.exit(1)

    if not os.path.exists(SSH_KEY):
        print(f"❌ SSH key not found at: {SSH_KEY}")
        print("💡 Pass SSH_KEY environment variable pointing to your private key.")
        sys.exit(1)

    os.chmod(SSH_KEY, 0o600)

    if not os.path.isdir(LOCAL_DIR):
        print(f"❌ Local folder not found: {LOCAL_DIR}")
        sys.exit(1)

    local_files = [f for f in os.listdir(LOCAL_DIR) if f.endswith(".mp4")]
    if not local_files:
        print(f"⚠️ No .mp4 files found in {LOCAL_DIR}")
        sys.exit(1)

    print(f"📁 Found {len(local_files)} local MP4 files in {LOCAL_DIR}")
    print(f"📥 Fetching metadata for playlist: {PLAYLIST_URL}...")

    is_dry_run = "--dry-run" in sys.argv
    if is_dry_run:
        print("🔍 Running in DRY-RUN mode (no files will be transferred).")
    cmd = ["yt-dlp", "--flat-playlist", "-J", PLAYLIST_URL]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        print(f"❌ yt-dlp error: {proc.stderr}")
        sys.exit(1)

    data = json.loads(proc.stdout)
    entries = data.get("entries", [])
    print(f"📋 Retrieved {len(entries)} playlist entries from YouTube.")

    # Match local files to playlist YouTube IDs
    matches = []
    unmatched_files = list(local_files)

    for e in entries:
        yt_id = e.get("id")
        yt_title = e.get("title", "")
        if not yt_id or not yt_title or "[Deleted" in yt_title or "[Private" in yt_title:
            continue

        norm_yt = normalize(yt_title)
        best_file = None
        best_score = 0.0
        for f in unmatched_files:
            norm_f = normalize(os.path.splitext(f)[0])
            score = difflib.SequenceMatcher(None, norm_yt, norm_f).ratio()
            if score > best_score:
                best_score = score
                best_file = f

        if best_file and best_score > 0.50:
            matches.append({
                "local_file": best_file,
                "local_path": os.path.join(LOCAL_DIR, best_file),
                "youtube_id": yt_id,
                "title": yt_title,
                "score": best_score,
            })
            unmatched_files.remove(best_file)

    print(f"\n✅ Matched {len(matches)} / {len(local_files)} files to YouTube IDs.")
    if unmatched_files:
        print(f"⚠️ {len(unmatched_files)} file(s) could not be automatically matched:")
        for uf in unmatched_files:
            print(f"   - {uf}")

    print("\n🚀 Preparing upload queue...")
    success_count = 0
    fail_count = 0

    for i, item in enumerate(matches, 1):
        local_path = item["local_path"]
        target_name = f"{item['youtube_id']}.mp4"
        title = item["title"]
        file_size_mb = os.path.getsize(local_path) / (1024 * 1024)

        print(f"\n[{i}/{len(matches)}] Uploading: {target_name} ({file_size_mb:.1f} MB)")
        print(f"       Title: {title}")

        # Upload file directly renamed to target YouTube ID
        rsync_cmd = [
            "rsync",
            "-avz",
            "--progress",
            "-e", f"ssh -o StrictHostKeyChecking=no -i {SSH_KEY}",
            local_path,
            f"{VPS_USER}@{VPS_HOST}:{VPS_TARGET_DIR}/{target_name}"
        ]

        if is_dry_run:
            print(f"       🔍 [Dry-Run] Would upload to {VPS_TARGET_DIR}/{target_name}")
            success_count += 1
            continue

        res = subprocess.run(rsync_cmd)
        if res.returncode == 0:
            success_count += 1
            print(f"       ✅ Successfully uploaded {target_name} to VPS")
        else:
            fail_count += 1
            print(f"       ❌ Failed to upload {target_name}")

    print("\n" + "=" * 60)
    print(f"🎉 Upload Complete! Successfully uploaded {success_count}/{len(matches)} videos.")
    if fail_count > 0:
        print(f"⚠️ Failed: {fail_count} files.")
    print(f"📁 Location on VPS: {VPS_TARGET_DIR}/")
    print("=" * 60)

if __name__ == "__main__":
    main()

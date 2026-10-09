#!/usr/bin/env python3
"""
MyKidsTube — Automatic Video ID Resolver & Renamer
==================================================
Identifies YouTube Video IDs for downloaded/encoded video files and renames
them to `<youtube_id>.mp4` for direct compatibility with the MyKidsTube
media streaming server and mobile app.

Usage:
  # Rename using a YouTube playlist URL (Most accurate for batch downloads):
  ./scripts/rename_videos.py --playlist "https://www.youtube.com/playlist?list=..."

  # Rename using a links.txt file (from queue export):
  ./scripts/rename_videos.py --links ~/Downloads/MyKidsTube_Raw/links.txt

  # Automatically search YouTube for each file title (zero URL needed):
  ./scripts/rename_videos.py --search

  # Dry run (preview matches and renames without touching files):
  ./scripts/rename_videos.py --playlist "<URL>" --dry-run

  # Undo previous renaming back to original titles:
  ./scripts/rename_videos.py --undo
"""

import os
import sys
import json
import re
import difflib
import argparse
import subprocess

YOUTUBE_ID_REGEX = re.compile(r'^[a-zA-Z0-9_-]{11}$')
EMBEDDED_ID_REGEX = re.compile(r'[[(_-]([a-zA-Z0-9_-]{11})[])]?(?:\.[a-zA-Z0-9]+)?$')

COMMON_NOISE_PATTERNS = [
    r'\[(?:official\s+video|official\s+audio|lyrics?|high\s+quality|hd|4k|hq|music\s+video|audio|video)\]',
    r'\((?:official\s+video|official\s+audio|lyrics?|high\s+quality|hd|4k|hq|music\s+video|audio|video|sing-along)\)',
    r'\b(?:official\s+video|official\s+audio|lyric\s+video|full\s+song|hd|hq|4k)\b',
    r'\(from\s+[^)]+\)',
    r'\[from\s+[^\]]+\]',
]

def clean_title(title: str) -> str:
    """Strip common promotional noise, brackets, and extra whitespace."""
    cleaned = title
    for pattern in COMMON_NOISE_PATTERNS:
        cleaned = re.sub(pattern, ' ', cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r'[\(\)\[\]\{\}_\-–—]', ' ', cleaned)
    cleaned = re.sub(r'\s+', ' ', cleaned).strip()
    return cleaned

def normalize_for_matching(text: str) -> str:
    """Produce normalized alphanumeric string for fuzzy comparison."""
    cleaned = clean_title(text)
    return re.sub(r'[^a-zA-Z0-9]', '', cleaned).lower()

def extract_embedded_id(filename: str):
    """Check if filename already contains an 11-character YouTube ID."""
    name_no_ext = os.path.splitext(filename)[0]
    if YOUTUBE_ID_REGEX.match(name_no_ext):
        return name_no_ext
    match = EMBEDDED_ID_REGEX.search(name_no_ext)
    if match:
        cand = match.group(1)
        if YOUTUBE_ID_REGEX.match(cand):
            return cand
    return None

def fetch_playlist_metadata(playlist_url: str):
    """Fetch all video entries from a YouTube playlist or channel via yt-dlp."""
    print(f"📥 Fetching metadata from YouTube: {playlist_url} ...")
    cmd = ["yt-dlp", "--no-update", "--flat-playlist", "-J", playlist_url]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        print(f"❌ yt-dlp error: {proc.stderr.strip()}")
        return []
    try:
        data = json.loads(proc.stdout)
    except Exception as e:
        print(f"❌ Failed to parse yt-dlp JSON output: {e}")
        return []

    entries = []
    for item in data.get("entries", []):
        vid = item.get("id")
        title = item.get("title") or ""
        if vid and title and "[Deleted" not in title and "[Private" not in title:
            entries.append({"id": vid, "title": title})
    print(f"📋 Retrieved {len(entries)} valid videos from playlist.")
    return entries

def fetch_links_file_metadata(links_file: str):
    """Extract YouTube IDs and query metadata from a text file of URLs."""
    if not os.path.isfile(links_file):
        print(f"❌ Links file not found: {links_file}")
        return []
    with open(links_file, "r") as f:
        urls = [line.strip() for line in f if line.strip().startswith("http")]
    
    entries = []
    print(f"📥 Parsing {len(urls)} URLs from: {links_file} ...")
    for u in urls:
        # Check v= parameter
        m = re.search(r'(?:v=|\/shorts\/|\/embed\/|youtu\.be\/)([a-zA-Z0-9_-]{11})', u)
        if m:
            entries.append({"id": m.group(1), "title": ""})
    return entries

def search_youtube_for_id(title: str):
    """Search YouTube for the video title using yt-dlp and return (id, yt_title)."""
    search_query = clean_title(title)
    cmd = ["yt-dlp", "--no-update", f"ytsearch1:{search_query}", "--print", "%(id)s\t%(title)s"]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode == 0 and proc.stdout.strip():
        parts = proc.stdout.strip().split("\t", 1)
        if len(parts) == 2 and YOUTUBE_ID_REGEX.match(parts[0]):
            return parts[0], parts[1]
    return None, None

def match_files_to_entries(files, entries):
    """Match local filenames against known YouTube entries using fuzzy matching."""
    matches = []
    unmatched = []

    available_entries = list(entries)

    for f in files:
        name_no_ext = os.path.splitext(f)[0]

        # 1. Check if already named with ID
        embedded = extract_embedded_id(f)
        if embedded:
            # Check if filename is already strictly `<id>.mp4`
            if name_no_ext == embedded:
                print(f"ℹ️ Already named with ID: {f} (skipped)")
                continue
            matches.append({
                "old_name": f,
                "new_name": f"{embedded}.mp4",
                "youtube_id": embedded,
                "title": name_no_ext,
                "confidence": 1.0,
                "method": "embedded_id"
            })
            continue

        norm_f = normalize_for_matching(name_no_ext)
        best_entry = None
        best_score = 0.0

        for entry in available_entries:
            norm_yt = normalize_for_matching(entry["title"])
            # difflib ratio
            score = difflib.SequenceMatcher(None, norm_f, norm_yt).ratio()
            # Also check substring containment boost
            if norm_f in norm_yt or norm_yt in norm_f:
                score = max(score, 0.85)
            if score > best_score:
                best_score = score
                best_entry = entry

        if best_entry and best_score >= 0.45:
            matches.append({
                "old_name": f,
                "new_name": f"{best_entry['id']}.mp4",
                "youtube_id": best_entry["id"],
                "title": best_entry["title"],
                "confidence": best_score,
                "method": "playlist_match"
            })
            available_entries.remove(best_entry)
        else:
            unmatched.append(f)

    return matches, unmatched

def undo_renaming(target_dir: str):
    """Reverts renamed files back to their original names using rename_map.json."""
    map_file = os.path.join(target_dir, "rename_map.json")
    if not os.path.isfile(map_file):
        print(f"❌ No rename_map.json found in {target_dir}. Cannot undo.")
        return

    with open(map_file, "r") as f:
        history = json.load(f)

    print(f"🔄 Undoing {len(history)} previous renames...")
    reverted = 0
    for item in history:
        cur_path = os.path.join(target_dir, item["new_name"])
        old_path = os.path.join(target_dir, item["old_name"])
        if os.path.exists(cur_path):
            os.rename(cur_path, old_path)
            print(f"   ↩️  {item['new_name']}  ➔  {item['old_name']}")
            reverted += 1
        else:
            print(f"   ⚠️  Current file not found: {item['new_name']}")

    os.remove(map_file)
    print(f"✅ Reverted {reverted} file(s) and cleared rename_map.json.")

def main():
    parser = argparse.ArgumentParser(description="Rename downloaded MP4 files to their YouTube Video IDs.")
    parser.add_argument("folder", nargs="?", default=os.path.expanduser("~/Downloads/MyKidsTube_Optimized"),
                        help="Folder containing MP4 files (default: ~/Downloads/MyKidsTube_Optimized)")
    parser.add_argument("--playlist", "-p", help="YouTube Playlist or Channel URL for batch matching")
    parser.add_argument("--links", "-l", help="Path to links.txt file containing YouTube URLs")
    parser.add_argument("--search", "-s", action="store_true", help="Search YouTube for unmatched files")
    parser.add_argument("--dry-run", "-n", action="store_true", help="Preview renames without executing")
    parser.add_argument("--undo", action="store_true", help="Revert renames using rename_map.json")

    args = parser.parse_args()
    target_dir = os.path.abspath(args.folder)

    if not os.path.isdir(target_dir):
        print(f"❌ Target directory does not exist: {target_dir}")
        sys.exit(1)

    if args.undo:
        undo_renaming(target_dir)
        return

    # List all MP4 files
    all_files = [f for f in os.listdir(target_dir) if f.lower().endswith(".mp4") and not f.startswith(".")]
    if not all_files:
        print(f"⚠️ No .mp4 files found in {target_dir}")
        return

    # Filter out files that are already pure 11-char IDs
    unresolved_files = [f for f in all_files if not YOUTUBE_ID_REGEX.match(os.path.splitext(f)[0])]
    already_valid = len(all_files) - len(unresolved_files)

    print(f"📁 Target folder: {target_dir}")
    print(f"   Total MP4 files: {len(all_files)}")
    if already_valid > 0:
        print(f"   Already named by ID: {already_valid}")
    print(f"   Files needing resolution: {len(unresolved_files)}")

    if not unresolved_files:
        print("✅ All files are already properly named with YouTube IDs! No action needed.")
        return

    entries = []
    if args.playlist:
        entries = fetch_playlist_metadata(args.playlist)
    elif args.links:
        entries = fetch_links_file_metadata(args.links)

    matches, unmatched = match_files_to_entries(unresolved_files, entries)

    # If any remain unmatched and --search is requested
    if unmatched and args.search:
        print(f"\n🔍 Searching YouTube for {len(unmatched)} unmatched file(s)...")
        still_unmatched = []
        for uf in unmatched:
            name_no_ext = os.path.splitext(uf)[0]
            print(f"   Searching for: '{clean_title(name_no_ext)}'...")
            yt_id, yt_title = search_youtube_for_id(name_no_ext)
            if yt_id:
                norm_local = normalize_for_matching(name_no_ext)
                norm_found = normalize_for_matching(yt_title or "")
                score = difflib.SequenceMatcher(None, norm_local, norm_found).ratio()
                if score >= 0.35:
                    matches.append({
                        "old_name": uf,
                        "new_name": f"{yt_id}.mp4",
                        "youtube_id": yt_id,
                        "title": yt_title,
                        "confidence": score,
                        "method": "search"
                    })
                    print(f"      ✅ Found match: {yt_id} ({yt_title})")
                    continue
            still_unmatched.append(uf)
        unmatched = still_unmatched

    # Display results
    print(f"\n{'='*70}")
    print(f"📋 MATCH SUMMARY ({len(matches)} matched, {len(unmatched)} unresolved)")
    print(f"{'='*70}")

    for m in matches:
        conf_str = f"{int(m['confidence'] * 100)}%" if m["confidence"] < 1.0 else "EXACT"
        print(f"• [{conf_str}] {m['old_name']}")
        print(f"  ➔ {m['new_name']}  ({m['title'][:60]})")

    if unmatched:
        print(f"\n⚠️ Unresolved files ({len(unmatched)}):")
        for u in unmatched:
            print(f"  ? {u}")
        print("\n💡 Tip: Supply --playlist '<URL>' or --search to resolve remaining titles.")

    if not matches:
        print("\n❌ No matches found to rename.")
        return

    if args.dry_run:
        print("\n🔍 DRY-RUN complete. No files were changed.")
        return

    # Execute renaming
    print(f"\n🚀 Renaming {len(matches)} file(s)...")
    rename_history = []
    renamed_count = 0

    for m in matches:
        src = os.path.join(target_dir, m["old_name"])
        dst = os.path.join(target_dir, m["new_name"])

        if src == dst:
            continue

        if os.path.exists(dst):
            print(f"   ⚠️ Skipping {m['old_name']}: Destination {m['new_name']} already exists.")
            continue

        try:
            os.rename(src, dst)
            rename_history.append(m)
            renamed_count += 1
        except Exception as e:
            print(f"   ❌ Error renaming {m['old_name']} -> {m['new_name']}: {e}")

    # Save rename_map.json
    map_file = os.path.join(target_dir, "rename_map.json")
    with open(map_file, "w") as f:
        json.dump(rename_history, f, indent=2)

    print(f"\n🎉 Successfully renamed {renamed_count} files to YouTube IDs!")
    print(f"📝 Mapping history saved to: {map_file}")
    print(f"💡 You can undo anytime with: ./scripts/rename_videos.py {target_dir} --undo")

if __name__ == "__main__":
    main()

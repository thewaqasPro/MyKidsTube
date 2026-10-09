#!/usr/bin/env bash
# ==============================================================================
# MyKidsTube — Residential Batch Downloader & HandBrake Sync Script for macOS
# ==============================================================================
# Usage:
#   ./scripts/sync-mykidstube.sh export                - Download pending links.txt
#   ./scripts/sync-mykidstube.sh download [URL]        - Download videos via local IP (or direct playlist URL)
#   ./scripts/sync-mykidstube.sh rename [PLAYLIST_URL] - Auto-rename video titles to YouTube IDs
#   ./scripts/sync-mykidstube.sh upload [PLAYLIST_URL] - Upload HandBrake MP4s to VPS (auto-renames & auto-syncs D1)
#   ./scripts/sync-mykidstube.sh sync-d1 [PLAYLIST_URL] - Sync local/VPS videos into Cloudflare D1 Catalog
#   ./scripts/sync-mykidstube.sh status                - Show current library and pending status
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment configuration if available
if [ -f "$REPO_ROOT/.env" ]; then
    set -a
    source "$REPO_ROOT/.env"
    set +a
elif [ -f "$REPO_ROOT/apps/server/.env" ]; then
    set -a
    source "$REPO_ROOT/apps/server/.env"
    set +a
fi

PORTAL_URL="${PORTAL_URL:-https://mykidstube.kidstube.workers.dev}"
VPS_HOST="${VPS_HOST:-155.248.219.73}"
VPS_USER="${VPS_USER:-ubuntu}"
SSH_KEY="${SSH_KEY:-$REPO_ROOT/vps/ssh-key-2026-09-27.key}"

RAW_DIR="${RAW_DIR:-$HOME/Downloads/MyKidsTube_Raw}"
OPTIMIZED_DIR="${OPTIMIZED_DIR:-$HOME/Downloads/MyKidsTube_Optimized}"

mkdir -p "$RAW_DIR" "$OPTIMIZED_DIR"

command_export() {
    echo "📥 Exporting pending download links from Cloudflare D1 ($PORTAL_URL)..."
    TEMP_LINKS=$(mktemp)
    if ! curl -fsS "$PORTAL_URL/api/queue/pending?format=txt" -o "$TEMP_LINKS"; then
        echo "❌ Error: Failed to fetch pending links from $PORTAL_URL/api/queue/pending" >&2
        rm -f "$TEMP_LINKS"
        exit 1
    fi

    # Validate that links.txt contains valid URLs (non-empty, lines starting with http:// or https://)
    grep -E '^https?://' "$TEMP_LINKS" > "$RAW_DIR/links.txt" || true
    rm -f "$TEMP_LINKS"

    if [ ! -s "$RAW_DIR/links.txt" ]; then
        echo "⚠️ No valid pending video URLs found in queue."
        return 0
    fi

    COUNT=$(wc -l < "$RAW_DIR/links.txt" | tr -d ' ')
    echo "✅ Exported $COUNT pending video URLs to: $RAW_DIR/links.txt"
    echo ""
    echo "Next steps:"
    echo "1. Feed '$RAW_DIR/links.txt' into 4K Video Downloader or run: ./scripts/sync-mykidstube.sh download"
    echo "2. Encode downloaded files in HandBrake using the 'Fast 720p30 (Web Optimized)' preset."
    echo "3. Save outputs to '$OPTIMIZED_DIR', then run: ./scripts/sync-mykidstube.sh upload"
}

command_download() {
    TARGET_URL="$1"

    if ! command -v yt-dlp &> /dev/null; then
        echo "⚠️ yt-dlp CLI not found on this Mac."
        echo "💡 Install yt-dlp via: brew install yt-dlp"
        exit 1
    fi

    if [ -n "$TARGET_URL" ]; then
        echo "🚀 Downloading from YouTube URL/Playlist directly using video IDs as filenames..."
        yt-dlp \
            -o "$RAW_DIR/%(id)s.%(ext)s" \
            -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" \
            --merge-output-format mp4 \
            --yes-playlist \
            --continue \
            "$TARGET_URL"
    else
        command_export
        if [ ! -s "$RAW_DIR/links.txt" ]; then
            echo "Nothing to download."
            exit 0
        fi

        echo ""
        echo "🚀 Downloading videos from queue on your local residential Mac connection..."
        yt-dlp \
            -a "$RAW_DIR/links.txt" \
            -o "$RAW_DIR/%(id)s.%(ext)s" \
            -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" \
            --merge-output-format mp4 \
            --no-playlist \
            --continue
    fi

    if command -v ffmpeg &> /dev/null; then
        echo "🎬 Ensuring +faststart on downloaded MP4 files..."
        for f in "$RAW_DIR"/*.mp4; do
            [ -e "$f" ] || continue
            TMP_FAST="${f}.fast.mp4"
            if ffmpeg -y -i "$f" -c copy -movflags +faststart "$TMP_FAST" 2>/dev/null; then
                mv "$TMP_FAST" "$f"
            else
                rm -f "$TMP_FAST"
            fi
        done
    fi

    echo "✅ Download complete in: $RAW_DIR"
}

command_rename() {
    PLAYLIST_OR_URL="$1"
    RENAME_SCRIPT="$SCRIPT_DIR/rename_videos.py"

    if [ ! -f "$RENAME_SCRIPT" ]; then
        echo "❌ Renaming script not found at: $RENAME_SCRIPT"
        exit 1
    fi

    echo "🏷️ Running YouTube ID resolver for files in: $OPTIMIZED_DIR"
    if [ -n "$PLAYLIST_OR_URL" ]; then
        python3 "$RENAME_SCRIPT" "$OPTIMIZED_DIR" --playlist "$PLAYLIST_OR_URL"
    elif [ -f "$RAW_DIR/links.txt" ]; then
        python3 "$RENAME_SCRIPT" "$OPTIMIZED_DIR" --links "$RAW_DIR/links.txt"
    else
        echo "🔍 No playlist provided. Searching YouTube automatically..."
        python3 "$RENAME_SCRIPT" "$OPTIMIZED_DIR" --search
    fi
}

command_upload() {
    OPTIONAL_PLAYLIST="$1"
    echo "📤 Scanning for HandBrake-encoded MP4 files in: $OPTIMIZED_DIR"
    FILE_COUNT=$(find "$OPTIMIZED_DIR" -maxdepth 1 -name "*.mp4" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$FILE_COUNT" -eq 0 ]; then
        echo "⚠️ No .mp4 files found in $OPTIMIZED_DIR."
        echo "   Please place your HandBrake-encoded files there before running upload."
        exit 1
    fi

    # Check if any files have human titles instead of pure 11-char YouTube IDs
    NON_ID_FILES=$(find "$OPTIMIZED_DIR" -maxdepth 1 -name "*.mp4" | grep -vE '/[a-zA-Z0-9_-]{11}\.mp4$' || true)
    if [ -n "$NON_ID_FILES" ]; then
        echo "⚠️ Detected files with human song titles instead of YouTube IDs."
        echo "🤖 Auto-resolving and renaming to YouTube IDs..."
        command_rename "$OPTIONAL_PLAYLIST"
    fi

    STAGING_DIR="/var/www/media/staging"
    TARGET_DIR="/var/www/media/videos"

    echo "Found $FILE_COUNT optimized MP4 file(s). Uploading to VPS ($VPS_HOST) staging..."

    if [ -f "$SSH_KEY" ]; then
        chmod 600 "$SSH_KEY" 2>/dev/null || true
        # Ensure staging and target directories exist on VPS
        ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "mkdir -p $STAGING_DIR $TARGET_DIR"

        # Rsync to staging directory
        rsync -avz --progress -e "ssh -i $SSH_KEY" \
            "$OPTIMIZED_DIR/"*.mp4 "$VPS_USER@$VPS_HOST:$STAGING_DIR/"

        # Atomically move files from staging into videos target directory
        ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "mv -f $STAGING_DIR/*.mp4 $TARGET_DIR/ 2>/dev/null || true"
        echo "✅ Files successfully staged and moved to target VPS storage ($TARGET_DIR)!"

        # Synchronize catalog with Cloudflare D1
        command_sync_d1 "$OPTIONAL_PLAYLIST"
    else
        echo "⚠️ SSH key not found at: $SSH_KEY"
        echo "   Set SSH_KEY environment variable pointing to your private key."
        exit 1
    fi
}

command_sync_d1() {
    OPTIONAL_PLAYLIST="$1"
    SYNC_SCRIPT="$SCRIPT_DIR/sync_to_d1.py"
    if [ -f "$SYNC_SCRIPT" ]; then
        echo "⚡ Synchronizing Cloudflare D1 Catalog so videos appear in Studio & App..."
        if [ -n "$OPTIONAL_PLAYLIST" ]; then
            python3 "$SYNC_SCRIPT" "$OPTIMIZED_DIR" --playlist "$OPTIONAL_PLAYLIST"
        else
            python3 "$SYNC_SCRIPT" "$OPTIMIZED_DIR"
        fi
    fi
}

command_status() {
    echo "📊 Checking KidsTube Library Status..."
    if ! curl -fsS "$PORTAL_URL/api/studio/stats" | python3 -m json.tool; then
        echo "❌ Error: Failed to fetch studio stats from $PORTAL_URL" >&2
        exit 1
    fi
}

command_prune() {
    echo "🧹 Scanning VPS storage for orphaned media files..."
    if [ ! -f "$SSH_KEY" ]; then
        echo "⚠️ SSH key not found at: $SSH_KEY"
        exit 1
    fi

    # Fetch active video IDs from Catalog API
    ACTIVE_IDS_FILE=$(mktemp)
    if ! curl -fsS "$PORTAL_URL/api/v1/catalog" | python3 -c "
import sys, json
data = json.load(sys.stdin)
videos = data.get('all_videos', [])
for v in videos:
    vid = v.get('youtube_id') or v.get('id')
    if vid:
        print(vid.strip())
" > "$ACTIVE_IDS_FILE"; then
        echo "❌ Error: Could not fetch active video list from $PORTAL_URL"
        rm -f "$ACTIVE_IDS_FILE"
        exit 1
    fi

    ACTIVE_COUNT=$(wc -l < "$ACTIVE_IDS_FILE" | tr -d ' ')
    echo "📋 Retrieved $ACTIVE_COUNT active video IDs from Cloudflare D1."

    # Inspect files on VPS
    TARGET_DIR="/var/www/media/videos"
    REMOTE_FILES=$(ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "ls -1 $TARGET_DIR/*.mp4 2>/dev/null || true")

    if [ -z "$REMOTE_FILES" ]; then
        echo "ℹ️ No video files currently found in VPS $TARGET_DIR."
        rm -f "$ACTIVE_IDS_FILE"
        return 0
    fi

    ORPHAN_COUNT=0
    while IFS= read -r file_path; do
        [ -z "$file_path" ] && continue
        FILENAME=$(basename "$file_path")
        VID_ID="${FILENAME%.mp4}"
        if ! grep -Fxq "$VID_ID" "$ACTIVE_IDS_FILE"; then
            echo "🗑️ Removing orphaned file on VPS: $FILENAME"
            ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "rm -f $TARGET_DIR/$FILENAME /var/www/media/thumbs/$VID_ID.*"
            ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
        fi
    done <<< "$REMOTE_FILES"

    rm -f "$ACTIVE_IDS_FILE"
    if [ "$ORPHAN_COUNT" -eq 0 ]; then
        echo "✅ VPS disk is fully synchronized with active catalog. No orphaned files."
    else
        echo "✅ Pruned $ORPHAN_COUNT orphaned media file(s) from VPS."
    fi
}

case "$1" in
    export)
        command_export
        ;;
    download)
        command_download "$2"
        ;;
    rename)
        command_rename "$2"
        ;;
    upload)
        command_upload "$2"
        ;;
    sync-d1)
        command_sync_d1 "$2"
        ;;
    prune)
        command_prune
        ;;
    status)
        command_status
        ;;
    *)
        echo "MyKidsTube Sync Helper"
        echo "Usage: $0 {export|download [URL]|rename [PLAYLIST_URL]|upload [PLAYLIST_URL]|sync-d1 [PLAYLIST_URL]|prune|status}"
        exit 1
        ;;
esac


#!/usr/bin/env bash
# ==============================================================================
# MyKidsTube — Residential Batch Downloader & HandBrake Sync Script for macOS
# ==============================================================================
# Usage:
#   ./scripts/sync-mykidstube.sh export     - Download pending links.txt
#   ./scripts/sync-mykidstube.sh download   - Download videos via local residential IP
#   ./scripts/sync-mykidstube.sh upload     - Upload HandBrake-encoded MP4s to VPS storage
#   ./scripts/sync-mykidstube.sh status     - Show current library and pending status
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
    command_export
    if [ ! -s "$RAW_DIR/links.txt" ]; then
        echo "Nothing to download."
        exit 0
    fi

    if ! command -v yt-dlp &> /dev/null; then
        echo "⚠️ yt-dlp CLI not found on this Mac."
        echo "💡 Install yt-dlp via: brew install yt-dlp"
        exit 1
    fi

    echo ""
    echo "🚀 Downloading videos on your local residential Mac connection..."
    yt-dlp \
        -a "$RAW_DIR/links.txt" \
        -o "$RAW_DIR/%(id)s.%(ext)s" \
        -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" \
        --merge-output-format mp4 \
        --no-playlist \
        --continue

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

command_upload() {
    echo "📤 Scanning for HandBrake-encoded MP4 files in: $OPTIMIZED_DIR"
    FILE_COUNT=$(find "$OPTIMIZED_DIR" -maxdepth 1 -name "*.mp4" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$FILE_COUNT" -eq 0 ]; then
        echo "⚠️ No .mp4 files found in $OPTIMIZED_DIR."
        echo "   Please place your HandBrake-encoded files there before running upload."
        exit 1
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
    else
        echo "⚠️ SSH key not found at: $SSH_KEY"
        echo "   Set SSH_KEY environment variable pointing to your private key."
        exit 1
    fi
}

command_status() {
    echo "📊 Checking KidsTube Library Status..."
    if ! curl -fsS "$PORTAL_URL/api/studio/stats" | python3 -m json.tool; then
        echo "❌ Error: Failed to fetch studio stats from $PORTAL_URL" >&2
        exit 1
    fi
}

case "$1" in
    export)
        command_export
        ;;
    download)
        command_download
        ;;
    upload)
        command_upload
        ;;
    status)
        command_status
        ;;
    *)
        echo "MyKidsTube Sync Helper"
        echo "Usage: $0 {export|download|upload|status}"
        exit 1
        ;;
esac

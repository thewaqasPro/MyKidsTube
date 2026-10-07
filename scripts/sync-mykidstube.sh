#!/bin/bash
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

PORTAL_URL="https://mykidstube.kidstube.workers.dev"
VPS_HOST="155.248.219.73"
VPS_USER="ubuntu"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SSH_KEY="$REPO_ROOT/vps/ssh-key-2026-09-27.key"

RAW_DIR="$HOME/Downloads/MyKidsTube_Raw"
OPTIMIZED_DIR="$HOME/Downloads/MyKidsTube_Optimized"

mkdir -p "$RAW_DIR" "$OPTIMIZED_DIR"

command_export() {
    echo "📥 Exporting pending download links from Cloudflare D1..."
    curl -s "$PORTAL_URL/api/queue/pending?format=txt" -o "$RAW_DIR/links.txt"
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
    if ! command -v yt-dlp &> /dev/null; then
        echo "⚠️ yt-dlp CLI not found on this Mac."
        echo "💡 You can download the videos using 4K Video Downloader or JDownloader with '$RAW_DIR/links.txt'."
        echo "   Or install yt-dlp via: brew install yt-dlp"
        exit 0
    fi

    echo ""
    echo "🚀 Downloading videos on your local residential Mac connection..."
    yt-dlp \
        -a "$RAW_DIR/links.txt" \
        -o "$RAW_DIR/%(id)s.%(ext)s" \
        -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/best" \
        --no-playlist \
        --continue
    echo "✅ Download complete in: $RAW_DIR"
}

command_upload() {
    echo "📤 Scanning for HandBrake-encoded MP4 files in: $OPTIMIZED_DIR"
    FILE_COUNT=$(find "$OPTIMIZED_DIR" -maxdepth 1 -name "*.mp4" | wc -l | tr -d ' ')

    if [ "$FILE_COUNT" -eq 0 ]; then
        echo "⚠️ No .mp4 files found in $OPTIMIZED_DIR."
        echo "   Please place your HandBrake-encoded files there, or drag & drop them directly at: $PORTAL_URL/upload"
        exit 1
    fi

    echo "Found $FILE_COUNT optimized MP4 file(s). Uploading to VPS ($VPS_HOST)..."

    if [ -f "$SSH_KEY" ]; then
        chmod 600 "$SSH_KEY"
        rsync -avz --progress -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
            "$OPTIMIZED_DIR/"*.mp4 "$VPS_USER@$VPS_HOST:/var/www/media/videos/"
        echo "✅ Files successfully uploaded to VPS storage!"
    else
        echo "⚠️ SSH key not found at: $SSH_KEY"
        echo "   Please use the Web Dropzone at: $PORTAL_URL/upload"
    fi
}

command_status() {
    echo "📊 Checking KidsTube Library Status..."
    curl -s "$PORTAL_URL/api/studio/stats" | python3 -m json.tool || true
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

#!/usr/bin/env python3
"""
MyKidsTube — Lightweight Media Disk Cleanup Microservice
Runs alongside Nginx to safely delete videos & thumbnails from VPS SSD
when removed from the Cloudflare Studio catalog.
"""

import hmac
import http.server
import json
import os
import re
import socketserver
import sys

PORT = int(os.environ.get("CLEANUP_PORT", 8081))
HOST = os.environ.get("CLEANUP_HOST", "0.0.0.0")
CLEANUP_SECRET = os.environ.get("CLEANUP_SECRET")
VIDEOS_DIR = os.environ.get("MEDIA_VIDEOS_DIR", "/var/www/media/videos")
THUMBS_DIR = os.environ.get("MEDIA_THUMBS_DIR", "/var/www/media/thumbs")
STAGING_DIR = os.environ.get("MEDIA_STAGING_DIR", "/var/www/media/staging")

SAFE_ID_REGEX = re.compile(r"^[a-zA-Z0-9_-]{1,64}$")


class CleanupHandler(http.server.BaseHTTPRequestHandler):
    def _send_json(self, status_code: int, data: dict):
        response_bytes = json.dumps(data).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_bytes)))
        self.end_headers()
        self.wfile.write(response_bytes)

    def _check_auth(self) -> bool:
        configured_secret = os.environ.get("CLEANUP_SECRET", "").strip()
        if not configured_secret:
            sys.stderr.write("[cleaner] REJECTED: CLEANUP_SECRET is not configured on server.\n")
            return False

        # Check X-Media-Secret or Authorization: Bearer <secret>
        header_secret = self.headers.get("X-Media-Secret")
        if not header_secret:
            auth_header = self.headers.get("Authorization", "")
            if auth_header.startswith("Bearer "):
                header_secret = auth_header[7:].strip()

        if not header_secret:
            return False

        return hmac.compare_digest(header_secret.strip(), configured_secret)

    def do_GET(self):
        if self.path in ("/health", "/api/storage/health"):
            self._send_json(200, {
                "status": "ok",
                "service": "mykidstube-cleanup-daemon",
                "videos_dir": VIDEOS_DIR,
                "thumbs_dir": THUMBS_DIR,
            })
            return

        self._send_json(404, {"error": "not_found"})

    def do_POST(self):
        if self.path not in ("/cleanup", "/api/storage/cleanup"):
            self._send_json(404, {"error": "not_found"})
            return

        if not self._check_auth():
            self._send_json(401, {"error": "unauthorized", "message": "Invalid or missing X-Media-Secret"})
            return

        content_length = int(self.headers.get("Content-Length", 0))
        if content_length <= 0 or content_length > 1024 * 1024:
            self._send_json(400, {"error": "invalid_payload", "message": "Payload too large or empty"})
            return

        try:
            body = self.rfile.read(content_length)
            payload = json.loads(body.decode("utf-8"))
        except Exception as e:
            self._send_json(400, {"error": "invalid_json", "message": str(e)})
            return

        raw_ids = []
        if isinstance(payload.get("ids"), list):
            raw_ids = payload["ids"]
        elif payload.get("id"):
            raw_ids = [payload["id"]]

        # Filter and validate IDs strictly to block path traversal (e.g. ../)
        valid_ids = [str(vid).strip() for vid in raw_ids if SAFE_ID_REGEX.match(str(vid).strip())]

        if not valid_ids:
            self._send_json(400, {"error": "no_valid_ids", "message": "No valid video IDs supplied"})
            return

        deleted_files = []
        deleted_ids = []
        total_freed_bytes = 0

        search_dirs = [
            (VIDEOS_DIR, [".mp4", ".mkv", ".webm"]),
            (THUMBS_DIR, [".webp", ".jpg", ".jpeg", ".png"]),
            (STAGING_DIR, [".mp4"]),
        ]

        for video_id in valid_ids:
            id_removed = False
            for target_dir, extensions in search_dirs:
                if not os.path.isdir(target_dir):
                    continue

                for ext in extensions:
                    candidate_path = os.path.join(target_dir, f"{video_id}{ext}")
                    if os.path.isfile(candidate_path):
                        try:
                            file_size = os.path.getsize(candidate_path)
                            os.remove(candidate_path)
                            total_freed_bytes += file_size
                            deleted_files.append(f"{video_id}{ext}")
                            id_removed = True
                        except Exception as del_err:
                            sys.stderr.write(f"Error removing {candidate_path}: {del_err}\n")

            if id_removed:
                deleted_ids.append(video_id)

        self._send_json(200, {
            "success": True,
            "deleted_count": len(deleted_ids),
            "deleted_ids": deleted_ids,
            "deleted_files": deleted_files,
            "freed_bytes": total_freed_bytes,
            "message": f"Cleaned {len(deleted_files)} file(s), freed {total_freed_bytes} bytes from VPS storage",
        })

    def log_message(self, format, *args):
        # Concise logging
        sys.stdout.write(f"[cleaner] {self.address_string()} - {format % args}\n")
        sys.stdout.flush()


def run():
    print(f"🚀 KidsTube Cleanup Daemon starting on {HOST}:{PORT}")
    print(f"   Videos storage: {VIDEOS_DIR}")
    print(f"   Thumbs storage: {THUMBS_DIR}")

    if not os.environ.get("CLEANUP_SECRET", "").strip():
        sys.stderr.write("⚠️  SECURITY WARNING: CLEANUP_SECRET environment variable is NOT set. All cleanup requests will fail closed (401 Unauthorized).\n")
    else:
        print("   Cleanup auth: Configured (fail-closed)")

    with socketserver.ThreadingTCPServer((HOST, PORT), CleanupHandler) as httpd:
        httpd.allow_reuse_address = True
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down cleanup daemon...")
            httpd.server_close()


if __name__ == "__main__":
    run()

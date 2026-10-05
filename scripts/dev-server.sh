#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Starting KidsTube Docker Media Server..."
cd "$DIR/apps/server"
docker compose up -d
echo "Media server running at http://localhost:8080/"

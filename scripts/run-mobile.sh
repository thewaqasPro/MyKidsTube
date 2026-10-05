#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Launching KidsTube Mobile App..."
cd "$DIR/apps/mobile"
flutter run "$@"

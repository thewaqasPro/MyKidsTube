#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Building Release Android APK..."
cd "$DIR/apps/mobile"
flutter build apk --release "$@"
echo "Build complete! APK available at: apps/mobile/build/app/outputs/flutter-apk/app-release.apk"

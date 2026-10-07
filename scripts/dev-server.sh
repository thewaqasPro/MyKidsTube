#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Checking TLS certificates..."
"$DIR/scripts/make-dev-cert.sh"

echo "Starting KidsTube Docker Media Server..."
cd "$DIR/apps/server"

# Load .env if present
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

PORT="${PORT_BINDING:-80}"
SSL_PORT="${SSL_PORT_BINDING:-443}"

docker compose up -d

echo "Media server running at:"
echo "  HTTP:   http://localhost:${PORT}/ (redirects to HTTPS)"
echo "  HTTPS:  https://localhost:${SSL_PORT}/"
echo "  Health: http://localhost:${PORT}/health or https://localhost:${SSL_PORT}/health"

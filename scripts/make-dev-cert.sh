#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSL_DIR="$DIR/apps/server/nginx/ssl"

mkdir -p "$SSL_DIR"

if [ -f "$SSL_DIR/cert.pem" ] && [ -f "$SSL_DIR/key.pem" ]; then
    echo "🔒 SSL certificates already exist in $SSL_DIR"
    exit 0
fi

DOMAIN="${1:-${CERT_DOMAIN:-localhost}}"

echo "🔐 Generating self-signed development TLS certificate for KidsTube ($DOMAIN)..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/key.pem" \
    -out "$SSL_DIR/cert.pem" \
    -subj "/C=US/ST=State/L=City/O=KidsTube/OU=Dev/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:localhost,DNS:$DOMAIN,IP:127.0.0.1"

chmod 600 "$SSL_DIR/key.pem"
chmod 644 "$SSL_DIR/cert.pem"

echo "✅ Self-signed TLS certificate generated successfully:"
echo "   Cert: $SSL_DIR/cert.pem"
echo "   Key:  $SSL_DIR/key.pem"

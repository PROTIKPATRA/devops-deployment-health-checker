#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:5000/health}"
MAX_RETRIES="${2:-5}"
SLEEP="${3:-2}"

echo "🔍 Checking health at $URL"

for i in $(seq 1 "$MAX_RETRIES"); do
  CODE=$(curl -s -o /tmp/health.json -w "%{http_code}" "$URL" || echo "000")
  echo "Attempt $i/$MAX_RETRIES -> HTTP $CODE"

  if [ "$CODE" = "200" ]; then
    echo "✅ Service healthy"
    cat /tmp/health.json
    echo
    exit 0
  fi
  sleep "$SLEEP"
done

echo "❌ Service unhealthy after $MAX_RETRIES attempts"
cat /tmp/health.json 2>/dev/null || true
exit 1
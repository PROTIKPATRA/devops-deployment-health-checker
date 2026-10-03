#!/usr/bin/env bash
# End-to-end demo: healthy deploy -> verified -> bad deploy -> detected
set -uo pipefail

PORT_OK=5050
PORT_BAD=5051
IMG=health-checker
URL_OK="http://localhost:${PORT_OK}/health"
URL_BAD="http://localhost:${PORT_BAD}/health"

banner() { printf "\n\033[1;36m=== %s ===\033[0m\n" "$1"; }

cleanup() {
  docker rm -f hc hc-fail >/dev/null 2>&1 || true
}
trap cleanup EXIT

cleanup

banner "1. Build image"
docker build -t "$IMG" . || exit 1

banner "2. Deploy HEALTHY container on :${PORT_OK}"
docker run -d --name hc -p "${PORT_OK}:5000" "$IMG" >/dev/null
sleep 5

banner "3. Verify healthy deployment"
./scripts/health-check.sh "$URL_OK" 5 2 || { echo "❌ expected success, got failure"; exit 1; }
echo "✅ healthy path verified"

banner "4. Teardown healthy deployment"
docker rm -f hc >/dev/null

banner "5. Deploy BROKEN container on :${PORT_BAD}"
docker run -d --name hc-fail -e HEALTHY=false -p "${PORT_BAD}:5000" "$IMG" >/dev/null
sleep 5

banner "6. Health check on broken deployment (must fail)"
set +e
./scripts/health-check.sh "$URL_BAD" 3 1
RC=$?
set -e
echo "Health-check exit code: $RC"

banner "7. Docker's own health status for hc-fail"
docker inspect --format='{{.State.Health.Status}}' hc-fail

banner "8. Container logs (503 trail)"
docker logs hc-fail 2>&1 | tail -n 10

if [ "$RC" -ne 0 ]; then
  echo -e "\n\033[1;32m✅ DEMO PASSED: bad deploy correctly detected\033[0m"
  exit 0
else
  echo -e "\n\033[1;31m❌ DEMO FAILED: bad deploy slipped through\033[0m"
  exit 1
fi
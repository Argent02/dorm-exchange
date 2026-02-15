#!/bin/bash
# ─── DormExchange Dev Launcher ─────────────────────────────
# Starts the database, backend, and optionally the Flutter app.
# Usage: ./dev.sh [device]
#   ./dev.sh              → starts DB + backend only
#   ./dev.sh macos        → starts DB + backend + Flutter on macOS
#   ./dev.sh iphone       → starts DB + backend + Flutter on iPhone
#   ./dev.sh <device-id>  → starts DB + backend + Flutter on a specific device

set -e

DEVICE="${1:-}"

# ─── Colors ────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}▸ Starting DormExchange dev environment...${NC}"

# ─── 1. Database ───────────────────────────────────────────
if docker ps --format '{{.Names}}' | grep -q dormexchange-db; then
  echo -e "${GREEN}✓ Database already running${NC}"
else
  echo -e "${YELLOW}▸ Starting database...${NC}"
  docker start dormexchange-db 2>/dev/null || docker compose up -d
  echo -e "${GREEN}✓ Database started${NC}"
fi

# ─── 2. Update local IP for physical device testing ───────
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "")
API_SERVICE="lib/services/api_service.dart"

if [ -n "$LOCAL_IP" ] && [ -f "$API_SERVICE" ]; then
  CURRENT_IP=$(grep "_localIp = " "$API_SERVICE" | sed "s/.*'\(.*\)'.*/\1/")
  if [ "$CURRENT_IP" != "$LOCAL_IP" ]; then
    sed -i '' "s|static const String _localIp = '.*'|static const String _localIp = '$LOCAL_IP'|" "$API_SERVICE"
    echo -e "${YELLOW}▸ Updated _localIp: $CURRENT_IP → $LOCAL_IP${NC}"
  else
    echo -e "${GREEN}✓ Local IP up to date ($LOCAL_IP)${NC}"
  fi
fi

# ─── 3. Backend ────────────────────────────────────────────
echo -e "${YELLOW}▸ Starting backend...${NC}"
cd backend
npm run dev &
BACKEND_PID=$!
cd ..

# Wait for backend to be ready
echo -n "  Waiting for API"
for i in $(seq 1 30); do
  if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}✓ Backend running on http://localhost:3000${NC}"
    break
  fi
  echo -n "."
  sleep 1
done

# ─── 4. Flutter (optional) ────────────────────────────────
if [ -n "$DEVICE" ]; then
  echo -e "${YELLOW}▸ Launching Flutter on device: $DEVICE${NC}"
  flutter run -d "$DEVICE"
else
  echo ""
  echo -e "${GREEN}✓ Dev environment ready!${NC}"
  echo -e "  Run ${YELLOW}flutter run -d <device>${NC} in another terminal to launch the app."
  echo ""
  # Keep backend running in foreground
  wait $BACKEND_PID
fi

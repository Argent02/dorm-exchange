#!/bin/bash
# ─── DormExchange Dev Launcher ─────────────────────────────
# Starts the database, backend, and optionally the Flutter app.
# Works on macOS and Linux.
#
# Usage: ./dev.sh [device]
#   ./dev.sh              → starts DB + backend only
#   ./dev.sh macos        → starts DB + backend + Flutter on macOS
#   ./dev.sh iphone       → starts DB + backend + Flutter on iPhone
#   ./dev.sh chrome       → starts DB + backend + Flutter on Chrome
#   ./dev.sh <device-id>  → starts DB + backend + Flutter on a specific device

set -e

# Load local device config (not tracked by git)
if [ -f .dev.config ]; then
  source .dev.config
fi

# Map friendly names to device IDs
if [ "$1" = "iphone" ]; then
  if [ -z "$IPHONE_DEVICE_ID" ]; then
    echo "⚠  No iPhone device ID configured."
    echo "   Create a .dev.config file in the project root with:"
    echo ""
    echo "   IPHONE_DEVICE_ID=\"your-device-id\""
    echo ""
    echo "   Find your device ID by running: flutter devices"
    exit 1
  fi
  DEVICE="$IPHONE_DEVICE_ID"
else
  DEVICE="${1:-}"
fi

# ─── Colors ────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ─── Helpers ───────────────────────────────────────────────

# Get the local network IP, cross-platform
get_local_ip() {
  case "$(uname -s)" in
    Darwin)
      ipconfig getifaddr en0 2>/dev/null || echo ""
      ;;
    Linux)
      hostname -I 2>/dev/null | awk '{print $1}' || echo ""
      ;;
    *)
      echo ""
      ;;
  esac
}

# Cross-platform in-place sed
portable_sed() {
  case "$(uname -s)" in
    Darwin)
      sed -i '' "$@"
      ;;
    *)
      sed -i "$@"
      ;;
  esac
}

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
LOCAL_IP=$(get_local_ip)
API_SERVICE="lib/services/api_service.dart"

if [ -n "$LOCAL_IP" ] && [ -f "$API_SERVICE" ]; then
  CURRENT_IP=$(grep "_localIp = " "$API_SERVICE" | sed "s/.*'\(.*\)'.*/\1/")
  if [ "$CURRENT_IP" != "$LOCAL_IP" ]; then
    portable_sed "s|static const String _localIp = '.*'|static const String _localIp = '$LOCAL_IP'|" "$API_SERVICE"
    echo -e "${YELLOW}▸ Updated _localIp: $CURRENT_IP → $LOCAL_IP${NC}"
  else
    echo -e "${GREEN}✓ Local IP up to date ($LOCAL_IP)${NC}"
  fi
else
  echo -e "${YELLOW}▸ Could not detect local IP — physical device testing may not work${NC}"
fi

# ─── 3. Backend ────────────────────────────────────────────
if [ ! -d "backend/node_modules" ]; then
  echo -e "${YELLOW}▸ Installing backend dependencies...${NC}"
  (cd backend && npm install)
fi

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
  if [ "$i" -eq 30 ]; then
    echo ""
    echo -e "${RED}✗ Backend failed to start within 30s${NC}"
    exit 1
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

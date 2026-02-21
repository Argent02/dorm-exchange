#!/bin/bash
# ─── DormExchange Dev Launcher ─────────────────────────────
# Starts the database, backend, and optionally the Flutter app.
# Works on macOS and Linux. Handles first-time setup automatically.
#
# Usage: ./dev.sh [device] [--release|-r]
#   ./dev.sh              → starts DB + backend + Flutter (prioritizes mobile, prompts if multiple)
#   ./dev.sh macos        → starts DB + backend + Flutter on macOS
#   ./dev.sh iphone       → starts DB + backend + Flutter on iPhone (wireless ok)
#   ./dev.sh --release    → same as above but in release mode (faster, no hot reload)
#   ./dev.sh iphone -r    → iPhone in release mode
#   ./dev.sh iphone-setup → prints wireless iPhone setup guide, opens Xcode
#   ./dev.sh chrome       → starts DB + backend + Flutter on Chrome
#   ./dev.sh <device-id>  → starts DB + backend + Flutter on a specific device

set -e

# Parse --release / -r from args
RELEASE_MODE=0
DEVICE_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--release" || "$arg" == "-r" ]]; then
    RELEASE_MODE=1
  else
    DEVICE_ARGS+=("$arg")
  fi
done

# Load local device config (not tracked by git)
if [ -f .dev.config ]; then
  source .dev.config
fi

# Handle iphone-setup before other logic
if [ "${DEVICE_ARGS[0]:-}" = "iphone-setup" ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────────────────────┐"
  echo "│  Wireless iPhone Setup for DormExchange                          │"
  echo "└─────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "1. Enable Developer Mode on iPhone:"
  echo "   Settings → Privacy & Security → Developer Mode (turn on, restart if asked)"
  echo ""
  echo "2. First-time pairing (USB required once):"
  echo "   • Connect iPhone to Mac via USB"
  echo "   • Open Xcode → Window → Devices and Simulators"
  echo "   • Select your iPhone"
  echo "   • Enable \"Connect via network\""
  echo "   • Wait for network icon, then disconnect USB"
  echo ""
  echo "3. Ensure Mac and iPhone are on the SAME Wi-Fi network"
  echo ""
  echo "4. Your Mac IP is used for the app to reach the backend."
  echo "   dev.sh auto-updates lib/services/api_service.dart when you run it."
  echo ""
  echo "5. Find your device ID: flutter devices"
  echo "   Optionally add to .dev.config: IPHONE_DEVICE_ID=\"<device-id>\""
  echo ""
  if [ "$(uname -s)" = "Darwin" ] && [ -d "/Applications/Xcode.app" ]; then
    echo "Opening Xcode (go to Window → Devices and Simulators to pair wirelessly)..."
    open -a Xcode 2>/dev/null || true
  elif [ "$(uname -s)" = "Darwin" ]; then
    echo "  (Xcode not found — install from App Store to use Devices window)"
  fi
  echo "Run ./dev.sh iphone when ready."
  echo ""
  exit 0
fi

# Map friendly names to device IDs
# When no device given: auto-detect first available (macos, chrome, simulator, etc.)
IPHONE_MODE=0
if [ "${DEVICE_ARGS[0]:-}" = "iphone" ]; then
  if [ -z "$IPHONE_DEVICE_ID" ]; then
    # Try to auto-detect first connected iOS device (physical or simulator)
    DETECTED=$(flutter devices 2>/dev/null | grep -E "iPhone|iPad" | grep -oE '[0-9a-fA-F-]{20,}' | head -1)
    if [ -n "$DETECTED" ]; then
      DEVICE="$DETECTED"
      echo "  (Auto-detected iOS device: $DEVICE)"
    else
      echo "⚠  No iPhone device ID configured or detected."
      echo ""
      echo "   Option A: Run ./dev.sh iphone-setup for wireless setup guide"
      echo ""
      echo "   Option B: Create .dev.config with your device ID:"
      echo "   IPHONE_DEVICE_ID=\"your-device-id\""
      echo ""
      echo "   Find your device ID: flutter devices"
      exit 1
    fi
  else
    DEVICE="$IPHONE_DEVICE_ID"
  fi
  IPHONE_MODE=1
else
  DEVICE="${DEVICE_ARGS[0]:-}"
  if [ -z "$DEVICE" ]; then
    # No device specified: prioritize mobile (iOS/Android), prompt if multiple
    RAW_DEVICES=$(flutter devices 2>/dev/null | awk -F' • ' '
      NF >= 3 {
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        gsub(/^[ \t]+|[ \t]+$/, "", $3);
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        if ($2 != "" && $3 != "") print $2 "|" $3 "|" $1;
      }
    ')
    MOBILE_LIST=()
    OTHER_LIST=()
    while IFS='|' read -r id platform name; do
      [[ -z "$id" ]] && continue
      if [[ "$platform" == "ios" || "$platform" == *"android"* ]]; then
        MOBILE_LIST+=("$id|$name")
      else
        OTHER_LIST+=("$id|$name")
      fi
    done <<< "$RAW_DEVICES"
    CANDIDATES=()
    if [[ ${#MOBILE_LIST[@]} -gt 0 ]]; then
      CANDIDATES=("${MOBILE_LIST[@]}")
    else
      CANDIDATES=("${OTHER_LIST[@]}")
    fi
    if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
      DEVICE=""
    elif [[ ${#CANDIDATES[@]} -eq 1 ]]; then
      DEVICE=$(echo "${CANDIDATES[0]}" | cut -d'|' -f1)
      NAME=$(echo "${CANDIDATES[0]}" | cut -d'|' -f2-)
      echo "  (Selected: $NAME)"
    else
      echo ""
      echo "  Multiple devices available. Choose one:"
      for i in "${!CANDIDATES[@]}"; do
        NAME=$(echo "${CANDIDATES[$i]}" | cut -d'|' -f2-)
        echo "    $((i+1))) $NAME"
      done
      echo "    q) Quit (skip launching app)"
      echo ""
      read -r -p "  Device [1]: " choice
      choice=${choice:-1}
      if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        DEVICE=""
      else
        idx=$((choice - 1))
        if [[ $idx -ge 0 && $idx -lt ${#CANDIDATES[@]} ]]; then
          DEVICE=$(echo "${CANDIDATES[$idx]}" | cut -d'|' -f1)
          echo "  (Selected: $DEVICE)"
        else
          DEVICE=$(echo "${CANDIDATES[0]}" | cut -d'|' -f1)
          echo "  (Invalid choice, using first: $DEVICE)"
        fi
      fi
    fi
  fi
  IPHONE_MODE=0
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

# ─── Preflight checks ────────────────────────────────────
echo -e "${GREEN}▸ Starting DormExchange dev environment...${NC}"

# Check required tools
for cmd in docker node npm flutter curl; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    echo -e "${RED}✗ Required tool '$cmd' is not installed.${NC}"
    exit 1
  fi
done

# ─── 1. Database ───────────────────────────────────────────
if docker ps --format '{{.Names}}' | grep -q dormexchange-db; then
  echo -e "${GREEN}✓ Database already running${NC}"
else
  echo -e "${YELLOW}▸ Starting database...${NC}"
  docker start dormexchange-db 2>/dev/null || docker compose up -d
  # Wait for Postgres to be ready to accept connections
  echo -n "  Waiting for database"
  for i in $(seq 1 15); do
    if docker exec dormexchange-db pg_isready -U postgres > /dev/null 2>&1; then
      echo ""
      echo -e "${GREEN}✓ Database started${NC}"
      break
    fi
    if [ "$i" -eq 15 ]; then
      echo ""
      echo -e "${RED}✗ Database failed to start within 15s${NC}"
      exit 1
    fi
    echo -n "."
    sleep 1
  done
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

# ─── 3. Backend setup ─────────────────────────────────────

# Auto-create .env from .env.example on first run
if [ ! -f "backend/.env" ]; then
  if [ -f "backend/.env.example" ]; then
    cp backend/.env.example backend/.env
    echo -e "${YELLOW}▸ Created backend/.env from .env.example (using default local dev settings)${NC}"
  else
    echo -e "${RED}✗ backend/.env.example not found — cannot configure backend${NC}"
    exit 1
  fi
fi

# Check for Firebase service account key
GOOGLE_CREDS=$(grep 'GOOGLE_APPLICATION_CREDENTIALS' backend/.env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
if [ -n "$GOOGLE_CREDS" ] && [ ! -f "backend/$GOOGLE_CREDS" ]; then
  echo -e "${RED}✗ Firebase service account key not found at backend/$GOOGLE_CREDS${NC}"
  echo "  Download it from Firebase Console > Project Settings > Service Accounts"
  echo "  Save it as backend/$GOOGLE_CREDS"
  exit 1
fi

# Install npm dependencies if missing
if [ ! -d "backend/node_modules" ]; then
  echo -e "${YELLOW}▸ Installing backend dependencies...${NC}"
  (cd backend && npm install)
fi

# Generate Prisma client if missing
if [ ! -d "backend/src/generated/prisma" ]; then
  echo -e "${YELLOW}▸ Generating Prisma client...${NC}"
  (cd backend && npx prisma generate)
fi

# Apply any pending database migrations (silent, no prompt)
echo -e "${YELLOW}▸ Applying database migrations...${NC}"
MIGRATE_OUTPUT=$(cd backend && npx prisma migrate deploy 2>&1)
MIGRATE_EXIT=$?
if [ "$MIGRATE_EXIT" -eq 0 ]; then
  echo -e "${GREEN}✓ Database schema up to date${NC}"
else
  echo -e "${RED}✗ Migration failed${NC}"
  echo ""
  echo "$MIGRATE_OUTPUT" | sed 's/^/  /'
  echo ""
  echo -e "${YELLOW}How to fix:${NC}"
  echo "  • Database connection refused? Ensure Docker is running and Postgres is up:"
  echo "    docker compose up -d"
  echo ""
  echo "  • Wrong credentials? Check backend/.env DATABASE_URL matches docker-compose.yml"
  echo "    (postgres:postgres@localhost:5432/dormexchange)"
  echo ""
  echo "  • First-time setup or schema drift? Create/apply migrations manually:"
  echo "    cd backend && npx prisma migrate dev --name <migration_name>"
  exit 1
fi

# ─── 4. Backend server ───────────────────────────────────
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

# ─── 5. Flutter (optional) ────────────────────────────────
if [ -n "$DEVICE" ]; then
  if [ "$IPHONE_MODE" = "1" ]; then
    echo ""
    echo -e "${YELLOW}▸ iPhone mode: Ensure Mac and iPhone are on same Wi‑Fi.${NC}"
    echo -e "${YELLOW}  Backend reachable at: http://${LOCAL_IP:-<local-ip>}:3000${NC}"
    echo ""
  fi
  if [ "$RELEASE_MODE" = "1" ]; then
    echo -e "${YELLOW}▸ Launching Flutter in release mode on device: $DEVICE${NC}"
    flutter run -d "$DEVICE" --release
  else
    echo -e "${YELLOW}▸ Launching Flutter on device: $DEVICE${NC}"
    flutter run -d "$DEVICE"
  fi
else
  echo ""
  echo -e "${GREEN}✓ Dev environment ready!${NC}"
  echo -e "  No device detected. Run ${YELLOW}flutter run -d <device>${NC} to launch the app."
  echo "  Example: ./dev.sh macos  |  ./dev.sh chrome  |  ./dev.sh iphone  |  ./dev.sh iphone -r"
  echo ""
  # Keep backend running in foreground
  wait $BACKEND_PID
fi

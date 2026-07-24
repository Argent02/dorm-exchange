# DormExchange

A mobile app for students to list, sell, or give away items to other students in their dorm with built-in messaging and safe exchange locations.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Dart) |
| Backend API | Express + TypeScript |
| Database | PostgreSQL |
| ORM | Prisma |
| Auth | Firebase Auth |
| Messaging | PostgreSQL (authoritative) + Firebase RTDB signal stream |
| Image Storage | Firebase Storage |
| Hosting | Railway (planned) |

## Current Repository Status

### Implemented and working

- Firebase auth with backend user sync
- Listings CRUD, status updates, and saved listings flows
- Conversations/messages with backend-authoritative persistence and RTDB signaling
- Profile/settings flows, including dorm field support and sold/taken visibility in exchanges
- Server-synced notification preferences with local cache fallback
- Release API base URL hardening via `--dart-define=API_BASE_URL=...`
- Contract CI checks for Flutter analysis/tests, backend build, and backend tests
- Backend Vitest integration test suite for core auth/listing/conversation/exchange routes

### Still pending before broad production/TestFlight rollout

- iOS deployment target warning cleanup
- Final legal/compliance content and public policy URLs
- Ongoing dependency vulnerability monitoring for unresolved transitive advisories

## Project Structure

```
dormexchange/
├── backend/             # Express + TypeScript API
│   ├── prisma/          # Prisma schema & migrations
│   ├── src/
│   │   ├── routes/      # API route handlers
│   │   ├── middleware/   # Auth middleware
│   │   ├── lib/         # Prisma client, Firebase init
│   │   └── index.ts     # App entry point
│   └── prisma.config.ts # Prisma CLI configuration
├── lib/                 # Flutter app source
├── dev.sh               # One-command dev launcher (macOS & Linux)
├── dev.ps1              # One-command dev launcher (Windows PowerShell)
├── docker-compose.yml   # Local PostgreSQL
└── pubspec.yaml         # Flutter dependencies
```

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) v20+
- [Flutter](https://flutter.dev/) SDK
- [Docker](https://www.docker.com/) (for local PostgreSQL)
- A Firebase project with Authentication enabled

### First-Time Setup

Before running the app for the first time, you need to configure Firebase.

**1. Backend — Firebase service account key:**

1. Go to [Firebase Console](https://console.firebase.google.com/) > Project Settings > Service Accounts
2. Click "Generate New Private Key"
3. Save the file as `serviceAccountKey.json` in the `backend/` directory

**2. Flutter — Firebase client config:**

The following files are gitignored and must be generated locally:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Generate them with the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/):

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This prompts you to select your Firebase project and creates all three files.

**3. Flutter dependencies:**

```bash
flutter pub get
```

That's it. Everything else is handled automatically by the dev script.

### Running the App

#### macOS / Linux

```bash
# Start DB + backend only
./dev.sh

# Start DB + backend + Flutter on a device
./dev.sh macos        # macOS desktop
./dev.sh chrome       # Web browser
./dev.sh iphone       # Physical iPhone (wireless ok; auto-detects or use .dev.config)
./dev.sh iphone-setup # Print wireless iPhone setup guide, open Xcode
./dev.sh <device-id>  # Specific device (find IDs via `flutter devices`)
```

#### Windows (PowerShell)

```powershell
# Start DB + backend only
.\dev.ps1

# Start DB + backend + Flutter on a device
.\dev.ps1 chrome       # Web browser
.\dev.ps1 <device-id>  # Specific device (find IDs via `flutter devices`)
```

#### What the scripts handle automatically

On every run:
- Starts PostgreSQL (or skips if already running, waits until ready)
- Detects your machine's local IP and updates Flutter config for physical device testing
- Creates `backend/.env` from `.env.example` if missing
- Installs npm packages if `node_modules` is missing
- Generates Prisma client if missing
- Applies any pending database migrations (no prompts)
- Starts the backend and waits for it to be healthy
- Launches Flutter on the specified device

On a fresh clone, the only manual steps are Firebase setup (above) — everything else is automatic.

### Environment Variables

The backend uses a `.env` file in the `backend/` directory. The dev script creates it automatically from `.env.example` on first run.

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string. Default for local Docker: `postgresql://postgres:postgres@localhost:5432/dormexchange?schema=public` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Yes | Path to Firebase service account JSON file (e.g., `./serviceAccountKey.json`) |
| `NODE_ENV` | No | Runtime environment. Defaults to `development` in local usage. |
| `PORT` | No | Server port. Defaults to `3000` |
| `CORS_ORIGIN` | Required in production | Comma-separated allowed origins for production CORS policy. Optional in local development. |

The backend validates required variables on startup and prints a clear error if any are missing.

### Release Build API Configuration (Required)

Release builds require an explicit API base URL:

```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

Notes:
- `API_BASE_URL` is required in release mode and must be an absolute non-localhost URL.
- Debug/local workflows continue to use local network defaults from `ApiService`.

### Testing on a Physical Device (Including Wireless iPhone)

**Wireless iPhone:** Run `./dev.sh iphone-setup` for a step-by-step guide. You'll need to pair once via USB in Xcode (Window → Devices → Connect via network), then you can run wirelessly. Mac and iPhone must be on the same Wi-Fi.

When running on a physical phone, the app connects to the backend over your local network. The dev scripts handle IP detection automatically.

If running manually, find your machine's IP:
- **macOS:** `ipconfig getifaddr en0`
- **Linux:** `hostname -I | awk '{print $1}'`
- **Windows:** `ipconfig` (look for IPv4 Address under your Wi-Fi adapter)

Then update `_localIp` in `lib/services/api_service.dart`.

### Physical Device Config (`.dev.config` / `.dev.config.ps1`)

`./dev.sh iphone` auto-detects your iPhone if one is connected. To use a specific device, create a config file in the project root (gitignored):

**macOS / Linux** — `.dev.config`:
```bash
IPHONE_DEVICE_ID="your-device-id"
```

**Windows** — `.dev.config.ps1`:
```powershell
$env:IPHONE_DEVICE_ID = "your-device-id"
```

Find your device ID with `flutter devices`.

## Useful Commands

```bash
# Dev environment (macOS/Linux)
./dev.sh              # Start DB + backend
./dev.sh macos        # Start everything + Flutter on macOS
./dev.sh iphone       # Start everything + Flutter on iPhone (wireless)
./dev.sh iphone-setup # Wireless iPhone setup guide
./dev.sh chrome       # Start everything + Flutter on Chrome

# Dev environment (Windows)
.\dev.ps1             # Start DB + backend
.\dev.ps1 chrome      # Start everything + Flutter on Chrome

# Backend
cd backend
npm run dev          # Start dev server with hot reload
npm run build        # Compile TypeScript
npm run test         # Run backend Vitest integration tests
npm audit            # Audit backend dependencies
npm run db:migrate   # Run Prisma migrations
npm run db:studio    # Open Prisma Studio (visual DB browser)
npm run db:generate  # Regenerate Prisma client

# Checks
flutter analyze      # Static analysis for Flutter app
flutter test         # Flutter test suite (model/contract-focused)

# Database
docker compose up -d              # Start PostgreSQL (first time)
docker start dormexchange-db      # Restart existing container
docker compose down               # Stop PostgreSQL

# Flutter
flutter devices      # List available devices
flutter run -d macos # Run on macOS
flutter run -d chrome # Run on web
```

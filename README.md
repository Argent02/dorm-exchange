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
| Messaging | Firebase Realtime DB (planned) |
| Image Storage | Firebase Storage (planned) |
| Hosting | Railway (planned) |

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
├── docker-compose.yml   # Local PostgreSQL
└── pubspec.yaml         # Flutter dependencies
```

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) v20+
- [Flutter](https://flutter.dev/) SDK
- [Docker](https://www.docker.com/) (for local PostgreSQL)
- A Firebase project with Authentication enabled

### Quick Start (recommended)

A dev script is included that starts everything in one command:

```bash
# Start DB + backend only
./dev.sh

# Start DB + backend + Flutter on a device
./dev.sh macos        # macOS desktop
./dev.sh chrome       # Web browser
./dev.sh iphone       # Physical iPhone
./dev.sh <device-id>  # Specific device (find IDs via `flutter devices`)
```

The script automatically:
- Starts PostgreSQL (or skips if already running)
- Detects your Mac's local IP and updates the Flutter config for physical device testing
- Starts the backend and waits for it to be healthy
- Launches the Flutter app on the specified device

### Manual Setup

If you prefer to start each service manually:

#### 1. Start the Database

```bash
docker compose up -d
```

This starts PostgreSQL on `localhost:5432` with database `dormexchange`.

#### 2. Set Up the Backend

```bash
cd backend

# Install dependencies
npm install

# Copy env file and configure
cp .env.example .env
# Edit .env with your DATABASE_URL and Firebase service account path

# Generate Prisma client
npx prisma generate

# Run database migrations
npx prisma migrate dev --name init

# Start the dev server (with hot reload)
npm run dev
```

The API will be running at `http://localhost:3000`.

#### 3. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/) > Project Settings > Service Accounts
2. Click "Generate New Private Key"
3. Save the file as `serviceAccountKey.json` in the `backend/` directory
4. Make sure `GOOGLE_APPLICATION_CREDENTIALS` in `.env` points to it

#### 4. Run the Flutter App

```bash
flutter pub get
flutter run
```

### Testing on a Physical Device

When running on a physical iPhone or Android device, the app needs to reach the backend over your local network (not `localhost`).

- Make sure your phone and Mac are on the **same Wi-Fi network**
- The `./dev.sh` script handles this automatically by updating `_localIp` in `lib/services/api_service.dart`
- If running manually, find your Mac's IP with `ipconfig getifaddr en0` and update the `_localIp` constant in `lib/services/api_service.dart`


## Useful Commands

```bash
# Dev environment
./dev.sh              # Start DB + backend
./dev.sh macos        # Start everything + Flutter on macOS

# Backend
cd backend
npm run dev          # Start dev server with hot reload
npm run build        # Compile TypeScript
npm run db:migrate   # Run Prisma migrations
npm run db:studio    # Open Prisma Studio (visual DB browser)

# Database
docker compose up -d              # Start PostgreSQL
docker start dormexchange-db      # Restart existing container
docker compose down               # Stop PostgreSQL

# Flutter
flutter devices      # List available devices
flutter run -d macos # Run on macOS
flutter run -d chrome # Run on web
```

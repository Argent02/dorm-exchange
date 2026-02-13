# DormExchange

A mobile app for students to list, sell, or give away items to other students in their dorm — with built-in messaging and safe exchange locations.

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

### 1. Start the Database

```bash
docker compose up -d
```

This starts PostgreSQL on `localhost:5432` with database `dormexchange`.

### 2. Set Up the Backend

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

### 3. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/) > Project Settings > Service Accounts
2. Click "Generate New Private Key"
3. Save the file as `serviceAccountKey.json` in the `backend/` directory
4. Make sure `GOOGLE_APPLICATION_CREDENTIALS` in `.env` points to it

### 4. Run the Flutter App

```bash
flutter pub get
flutter run
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/auth/login` | Verify Firebase token, create/return user |
| GET | `/auth/me` | Get current user profile |
| GET | `/listings` | List active listings (search, filter, paginate) |
| GET | `/listings/:id` | Get single listing |
| POST | `/listings` | Create a listing |
| PUT | `/listings/:id` | Edit own listing |
| PATCH | `/listings/:id/status` | Mark as sold/taken/deleted |
| GET | `/users/me` | Current user profile with listings |
| GET | `/users/:id` | Public user profile |

### Query Parameters for `GET /listings`

| Param | Type | Description |
|-------|------|-------------|
| `search` | string | Search title and description |
| `category` | string | Filter by category |
| `isFree` | boolean | Filter free items only |
| `page` | number | Page number (default: 1) |
| `limit` | number | Items per page (default: 20, max: 50) |

## Useful Commands

```bash
# Backend
cd backend
npm run dev          # Start dev server with hot reload
npm run build        # Compile TypeScript
npm run db:migrate   # Run Prisma migrations
npm run db:studio    # Open Prisma Studio (visual DB browser)

# Database
docker compose up -d    # Start PostgreSQL
docker compose down     # Stop PostgreSQL
```

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VibeTag is an offline-first iOS music app that uses AI to auto-tag songs and generate playlists. It has two main components:
- **Backend**: Node.js + TypeScript + Express.js (hexagonal architecture)
- **iOS**: Swift 6 + SwiftUI (MVVM)

## Backend Commands

```bash
cd backend

npm run dev          # Start dev server with hot reload (tsx watch)
npm run build        # Compile TypeScript to dist/
npm start            # Run compiled server
npm run test         # Run all tests (Vitest)
npm run lint         # ESLint
npm run format       # Prettier

# Database
npm run prisma:generate   # Regenerate Prisma client after schema changes
npm run prisma:migrate    # Run pending migrations (dev)

# Local DB (Docker)
docker-compose up -d  # Start PostgreSQL 16 on port 5432
```

To run a single test file: `npx vitest run src/tests/path/to/file.test.ts`

## iOS

Open `ios/VibeTag.xcodeproj` in Xcode. No CocoaPods or SPM — all native Apple frameworks. Build/run via Xcode or:
```bash
xcodebuild -scheme VibeTag -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Backend Architecture (Hexagonal)

Four layers with strict dependency rules (inner layers have no knowledge of outer):

1. **Domain** (`src/domain/`) — entities, value objects, interfaces. Zero external dependencies.
2. **Application** (`src/application/`) — use cases, DTOs, port interfaces. Depends only on Domain.
3. **Infrastructure** (`src/infrastructure/`) — Express controllers/routes, Prisma repositories, `GeminiAIService` (Google Gemini 2.5 Flash via Vercel AI SDK), `JwtTokenService`, `AppleAuthProvider`.
4. **Composition** (`src/composition/`) — `buildContainer()` wires all dependencies via constructor injection.

**Error handling**: All use cases return `Result<T, E>` (from `src/shared/`) — never throw for flow control.

**API routes**: `/api/v1/analyze`, `/api/v1/auth`, `/api/v1/songs`, `/api/v1/playlists`

**Database schema** (Prisma): `User`, `Song`, `Tag` (type: `SYSTEM | USER`), `SongTag` pivot with unique constraint `(songId, tagId, userId)`.

## iOS Architecture (MVVM)

- **Features/** — one folder per screen, each has `*View.swift` + `*ViewModel.swift`. ViewModels use `@Observable` macro and are `@MainActor`.
- **Domain/** — SwiftData models (`VTSong`, `Tag`), use case protocols, error types.
- **Core/** — `AppContainer` (DI), `APIClient` (URLSession), repositories (SwiftData, MusicKit, backend), `VibeTagSyncEngine`, `KeychainTokenStorage`.
- **Components/** — shared UI building blocks.

Navigation is managed via a Router pattern in `Core/Navigation/`.

## Key Workflows

**AI Auto-Tagging**: iOS `AnalyzeSongUseCase` → POST `/api/v1/analyze/song` → backend `GeminiAIService` generates tags → cached in DB → synced to iOS.

**Playlist Generation**: User prompt → backend extracts keywords via AI → matches user's songs by tag overlap → returns ranked top-50 → iOS exports to Apple Music via MusicKit.

**Authentication**: Apple Sign-In only. Guest mode works fully offline. On sign-in, `LoginWithAppleUseCase` validates the Apple token, creates/retrieves user, issues JWT. `VibeTagSyncEngine` pulls cloud data. JWT stored in Keychain.

## CI/CD

GitHub Actions (`.github/workflows/backend-ci.yml`) runs on PRs touching `backend/`: lint → type-check → test → build.

## Conventions

- **Backend**: single quotes, 2-space indent, 100-char line width (Prettier). `console.warn`/`console.error` allowed; no `console.log` in production code.
- **iOS**: Swift 6 strict concurrency. `@MainActor` on all ViewModels. Tokens in Keychain, never UserDefaults.
- **IDOR prevention**: backend always verifies the requesting user owns the resource being accessed.

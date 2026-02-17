# VibeTag Backend Architecture

This document outlines the architectural patterns, directory structure, and programming guidelines used in the VibeTag backend.

The server follows a **Clean (Hexagonal) Architecture** approach — Ports & Adapters — ensuring that business rules remain completely independent of frameworks, databases, and external services.

## Tech Stack

- **Runtime:** Node.js (Latest LTS)
- **Language:** TypeScript (strict mode, no `any`)
- **Web Framework:** Express.js
- **Database:** PostgreSQL 16 + Prisma ORM
- **AI Integration:** Google Gemini 2.5 Flash (via Vercel AI SDK)
- **Authentication:** Apple Sign-In + JWT
- **Validation:** Zod
- **Testing:** Vitest
- **Error Tracking:** Sentry

## 🏗 Directory Structure & Layers

### 1. Domain Layer (`src/domain/`)
The innermost layer. Pure TypeScript with zero external dependencies. Contains core business rules and identity.

* **`entities/`** — Rich domain models: `User`, `Song`, `Analysis`, `VibeTag`.
* **`value-objects/`** — Immutable, self-validating types that enforce domain invariants.
  * **`ids/`** — Typed identifiers (`UserId`, `SongId`, `AnalysisId`, `VibeTagId`, `AppleId`).
  * `Email`, `SongMetadata`, `VTDate`.
* **`errors/`** — Domain error hierarchy (`AppError` → `ValidationError`, `UseCaseError`, `AuthError`, `AIServiceError`).
* **`services/`** — Domain-level contracts (`AIService` interface) and pure domain logic (`TagDeduplicationService`).

### 2. Application Layer (`src/application/`)
Orchestrates data flow. Implements use cases that compose domain logic. Depends **only** on Domain.

* **`use-cases/`** — One class per business action, each exposing an `execute()` method that returns `Result<T, E>`.
  * `AnalyzeUseCase` — Single and batch song analysis via AI.
  * `UpdateSongTagsUseCase` — Overwrites a song's tags for a user.
  * `GetUserLibraryUseCase` — Paginated retrieval of a user's synced songs.
  * `GeneratePlaylistUseCase` — AI-driven playlist generation from a natural-language prompt.
  * `auth/LoginWithAppleUseCase` — Validates Apple identity token, upserts user, issues JWT.
  * `auth/DeleteAccountUseCase` — Cascading account deletion.
* **`ports/`** — Interface contracts that Infrastructure must implement (`IAnalysisRepository`, `ISongRepository`, `UserRepository`, `IAuthProvider`, `ITokenService`).
* **`dtos/`** — Data Transfer Objects for request/response boundaries (`AnalyzeDTO`, `SongDTO`, `PlaylistDTO`, `LoginWithAppleDTO`).

### 3. Infrastructure Layer (`src/infrastructure/`)
Implements the ports defined in Application. Contains all framework-specific and I/O code.

* **`http/`** — Express HTTP layer.
  * **`routes/`** — Route definitions mounted under `/api/v1` (`analyze`, `auth`, `songs`, `playlists`). Assembled by `index.ts` into a single app router.
  * **`controllers/`** — Orchestrate the request/response cycle: validate input with Zod, invoke use cases, map `Result` to HTTP responses.
  * **`middleware/`** — `createVerifyToken`: Bearer token extraction and JWT verification.
  * **`utils/`** — `errorHandler`: maps domain errors to appropriate HTTP status codes.
* **`persistence/repositories/`** — Prisma-backed implementations of repository ports (`PrismaAnalysisRepository`, `PrismaSongRepository`, `PrismaUserRepository`).
* **`mappers/`** — Translate Prisma database records into domain entities (`SongMapper`, `UserMapper`).
* **`services/`** — External service adapters:
  * `GeminiAIService` — Implements `AIService` port using Google Gemini.
  * `GroqAIService` — Alternative AI provider adapter.
  * `AppleAuthProvider` — Apple identity token verification.
* **`security/`** — `JwtTokenService`: JWT generation and verification (implements `ITokenService`).
* **`database/`** — Prisma client singleton.

### 4. Composition Layer (`src/composition/`)
Wires everything together. The only layer that knows about all other layers.

* **`containers/container.ts`** — `buildContainer()` instantiates every dependency via constructor injection and returns the fully-wired dependency graph.
* **`config/config.ts`** — Environment variable loading and validation.

### 5. Shared (`src/shared/`)
Cross-cutting utilities used by any layer.

* `Result<T, E>` — Functional error-handling monad. All use cases return Results; exceptions are never thrown for flow control.
* `TextSanitizer` — Input sanitization for AI prompts.

---

## 🔄 Data Flow

```
Client Request
  → Route (defines endpoint + applies middleware)
    → Controller (Zod validation → calls Use Case)
      → Use Case (orchestrates domain logic, calls Ports)
        → Repository / Service (Prisma queries, AI calls)
          → Domain Entity / Value Object (validated, returned)
        ← Result<T, E>
      ← Result<T, E>
    ← HTTP Response (mapped from Result)
```

**Key rule:** Data always flows inward. Inner layers never import outer layers. The Domain knows nothing about Express, Prisma, or Gemini.

---

## 📦 Data Model (Prisma)

| Model    | Key Fields | Notes |
|----------|-----------|-------|
| `User`   | id (UUID), email (unique), firstName, lastName, appleUserIdentifier (unique) | Authentication anchor |
| `Song`   | id (String), appleMusicId, title, artist, album, genre, artworkUrl | ID is ISRC or Apple Music ID |
| `Tag`    | id (UUID), name, color, type (`SYSTEM` / `USER`), ownerId (nullable) | Unique constraint: `(name, ownerId)` |
| `SongTag`| id (UUID), songId, tagId, userId | Explicit pivot table. Unique: `(songId, tagId, userId)` |

---

## 🌐 API Endpoints

All routes are mounted under `/api/v1`. Every endpoint except `/auth` and `/health` requires a valid Bearer JWT.

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/auth/apple` | Login/register via Apple Sign-In |
| `DELETE`| `/auth/me` | Delete current user's account and data |
| `POST` | `/analyze/song` | AI-analyze a single song |
| `POST` | `/analyze/batch` | AI-analyze multiple songs |
| `GET`  | `/songs/synced` | Paginated user library |
| `PATCH`| `/songs/:id` | Update a song's tags |
| `POST` | `/playlists/generate` | Generate playlist from natural-language prompt |

---

## 💻 Coding Guidelines & Standards

### 1. Clean Architecture (Strict Separation)
- **Domain:** Pure TypeScript. No framework imports. Entities and Value Objects encapsulate core logic with self-validation.
- **Application:** Use Cases implement `execute(input) → Result<Output>`. Ports (Repositories/Services) are interfaces defined here, implemented in Infrastructure.
- **Infrastructure:** Routes define endpoints and map to Controller methods. Controllers validate with Zod, invoke Use Cases, and map Results to HTTP. Repositories use Prisma exclusively.

### 2. Error Handling
- **Result Pattern:** All Application and Domain returns use `Result<T, E>`. Never throw exceptions for flow control.
- **HTTP Mapping:** Controllers translate `Result.fail` into appropriate status codes via the error handler utility.
- **Production Safety:** Never return stack traces or raw database errors to the client.

### 3. TypeScript Specifics
- **Strict Typing:** No `any`. Define interfaces for everything.
- **Naming:** PascalCase for classes (`CreateUserUseCase`), camelCase for variables/functions. No prefixes.
- **Formatting:** Single quotes, 2-space indent, 100-char line width (Prettier).

### 4. Testing
- Domain and Application logic must be unit tested with Vitest.
- Infrastructure tests use mocked dependencies (no real DB or API calls).

---

## 🛡️ Security Standards (OWASP Top 10)

**Principle:** Security by Design & Default.

1. **Input Validation (Injection Prevention):**
   - Validate ALL incoming requests (body, query, params) using Zod schemas in the Controller layer.
   - Use Prisma ORM methods strictly — avoid `prisma.$queryRaw` unless absolutely necessary (and then use parameterized queries).

2. **Authentication & Access Control:**
   - All routes (except `/auth` and `/health`) are protected by the `verifyToken` middleware.
   - IDOR prevention: always verify the requesting user's `sub` (User ID) matches the resource owner.

3. **Security Misconfiguration:**
   - `helmet` middleware for secure HTTP headers (HSTS, No-Sniff, XSS Protection).
   - Generic error messages in production — no stack traces or raw DB errors.

4. **Vulnerable Dependencies:**
   - Regular `npm audit`. No abandoned packages.

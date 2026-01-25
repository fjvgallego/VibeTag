# VibeTag: Backend Technical Context

## Tech Stack
- **Runtime:** Node.js (Latest LTS).
- **Language:** TypeScript.
- **Web Framework:** Express.js (Keep it simple).
- **Database:** PostgreSQL 16 (Dockerized).
- **ORM:** Prisma.
- **Testing:** Vitest.

## Data Model (Prisma Schema Concept)
- `User`: id (UUID), appleUserIdentifier (Unique string).
- `Song`: id (String, stores Apple Music ID/ISRC), title, artist, artworkUrl.
- `Tag`: id (UUID), name, color, type (Enum: SYSTEM/USER), ownerId (Nullable UUID).
- `SongTag`: id (UUID), songId, tagId, userId.
  - *Note:* This must be an **explicit pivot table** to handle the user-specific relationship.

## Architecture & API
- **Pattern:** Layered Architecture (Routes -> Controllers -> Services -> Prisma).
- **Auth:** Passport Strategy (or similar middleware) to validate Apple `identityToken`.
- **Key Endpoints:**
  - `POST /auth/apple`: Handles Login/Registration.
  - `POST /sync`: Accepts a JSON diff of local changes.
  - `POST /analyze`: Receives song metadata, calls generic LLM service.

## 🛡️ Coding Guidelines (The "Rules of Engagement")

### 1. Layered Architecture (Strict Separation)
- **Controllers:** Input/Output only. They validate inputs (Zod/DTOs), call a Service, and return a JSON response. NO business logic here.
- **Services:** Pure business logic. This is where the magic happens.
- **Repositories/Prisma:** Database interaction only.

### 2. Clean Code & SOLID
- **Avoid Magic Strings:** Use Enums or Constants.
- **Error Handling:** Don't just `console.log`. Throw custom errors that the Global Error Handler can catch and format standard HTTP responses.
- **Tests:** Business logic must be unit tested with Vitest.

### 3. TypeScript Specifics
- **Strict Typing:** No `any`. Define interfaces for everything.
- **Naming:** PascalCase for Classes (`UserService`), camelCase for variables/functions (`getUser`). NO prefixes (`VTUser` is forbidden).

## 🛡️ Security Standards (OWASP Top 10)
**Principle:** Security by Design & Default.

1.  **Input Validation (Injection Prevention):**
    - **Rule:** Never trust client input.
    - **Implementation:** validate ALL incoming requests (Body, Query, Params) using **Zod** schemas in the Controller layer before passing data to Services.
    - **Database:** Use Prisma ORM methods strictly to prevent SQL Injection. Avoid `prisma.$queryRaw` unless absolutely necessary (and then use parameterized queries).

2.  **Authentication & Broken Access Control:**
    - **Rule:** Deny by default.
    - **Implementation:** All routes (except `/auth` and `/health`) must be protected by the `authenticate` middleware.
    - **Tokens:** Validate JWTs on every request. Ensure `sub` (User ID) matches the resource owner for data modification (IDOR prevention).

3.  **Security Misconfiguration:**
    - **Headers:** Use `helmet` middleware to set secure HTTP headers (HSTS, No-Sniff, XSS Protection).
    - **Error Handling:** NEVER return stack traces or raw database errors to the client in production. Use generic error messages (e.g., "Internal Server Error").

4.  **Vulnerable Dependencies:**
    - **Rule:** Regular auditing.
    - **Implementation:** Run `npm audit` regularly. Do not use abandoned packages.
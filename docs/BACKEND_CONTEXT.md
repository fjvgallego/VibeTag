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
- **Pattern:** Clean Architecture.
  - **Domain:** Enterprise business rules (Entities, Value Objects, Domain Errors). Dependency free.
  - **Application:** Application business rules (Use Cases, DTOs, Ports/Interfaces). Depends only on Domain.
  - **Infrastructure:** Frameworks & Drivers (Database/Prisma, Web/Express Controllers, External Services). Implements interfaces defined in Application.
  - **Composition:** Dependency Injection (Containers, Config). Wires everything together.
  - **Shared:** Common utilities (Result Type, specialized types).
- **Auth:** Passport Strategy (or similar middleware) to validate Apple `identityToken`.
- **Key Endpoints:**
  - `POST /auth/apple`: Handles Login/Registration.
  - `POST /sync`: Accepts a JSON diff of local changes.
  - `POST /analyze`: Receives song metadata, calls generic LLM service.

## 🛡️ Coding Guidelines (The "Rules of Engagement")

### 1. Clean Architecture (Strict Separation)
- **Domain:** Pure TypeScript. No dependencies on frameworks or libraries.
  - *Entities* & *Value Objects* encapsulate core logic.
- **Application:** Orchestrates the flow of data.
  - *Use Cases* implement specific user stories (`Execute(Input) -> Result<Output>`).
  - *Ports* (Repositories/Services) are interfaces defined here, implemented in Infrastructure.
- **Infrastructure:**
  - *Controllers* (HTTP): Validate input (Zod), invoke Use Cases, map Results to HTTP responses.
  - *Repositories* (Database): Implement the repository interfaces using Prisma.

### 2. Clean Code & SOLID
- **Avoid Magic Strings:** Use Enums or Constants.
- **Result Pattern:** Use the `Result<T, E>` type for all return values in Application and Domain layers. Do not throw exceptions for flow control.
- **Tests:** Domain and Application logic must be unit tested with Vitest.

### 3. TypeScript Specifics
- **Strict Typing:** No `any`. Define interfaces for everything.
- **Naming:** PascalCase for Classes (`CreateUserUseCase`), camelCase for variables/functions. NO prefixes.

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
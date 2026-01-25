# VibeTag: Backend Technical Context

## Tech Stack
- **Framework:** NestJS (Modular Monolith).
- **Language:** TypeScript.
- **Database:** PostgreSQL (Dockerized).
- **ORM:** Prisma.

## Data Model (Prisma Schema Concept)
- `User`: id (UUID), appleUserIdentifier (Unique string).
- `Song`: id (String, stores Apple Music ID/ISRC), title, artist, artworkUrl.
- `Tag`: id (UUID), name, color, type (Enum: SYSTEM/USER), ownerId (Nullable UUID).
- `SongTag`: id (UUID), songId, tagId, userId.
  - *Note:* This must be an **explicit pivot table** to handle the user-specific relationship.

## Architecture & API
- **Auth:** Passport Strategy to validate Apple `identityToken`.
- **Key Endpoints:**
  - `POST /auth/apple`: Handles Login/Registration and JWT issuance.
  - `POST /sync`: Accepts a JSON diff of local changes to sync to the cloud.
  - `POST /analyze`: Receives song metadata, calls a **Generative AI Service (LLM)**, and returns suggested tags. Abstract this service to allow swapping providers easily.
# ADR 0001: Hexagonal Architecture (Clean Architecture)

* **Status:** Accepted
* **Date:** 2026-01-25

## Context
We need to build a scalable application where business rules (music analysis, user management) are independent of external tools (Databases, AI APIs, Web Frameworks). We anticipate future changes in AI providers (OpenAI, Gemini) and music sources (Spotify, Apple Music).

## Decision
Adopt **Hexagonal Architecture (Ports & Adapters)**.
* **Domain:** Pure entities and logic with zero dependencies.
* **Application:** Use Cases and Ports (Interfaces).
* **Infrastructure:** Adapters (Prisma, GeminiService, Controllers).

## Consequences
* ✅ **Positive:** High decoupling. Switching from OpenAI to Gemini only required creating a new adapter without touching business logic.
* ✅ **Positive:** High testability (Ports can be easily mocked).
* ❌ **Negative:** Increased boilerplate (more files and folders) initially compared to traditional MVC architecture.
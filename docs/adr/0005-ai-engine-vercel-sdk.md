# ADR 0005: AI Engine and Vercel AI SDK Abstraction

* **Status:** Accepted
* **Date:** 2026-01-28

## Context
The core feature of the app is "Vibe" analysis. OpenAI requires payment, blocking the free MVP. Google Gemini offers a generous free tier. However, Google libraries undergo frequent changes, and we want to keep the door open to return to OpenAI or use other models in the future.

## Decision
1.  Use **Google Gemini (Flash Model)** as the initial provider due to zero cost.
2.  Use **Vercel AI SDK (`ai` + `@ai-sdk/google`)** as an abstraction layer instead of Google's native SDK.
3.  Implement **Zod** to enforce Structured Output and avoid manual JSON/Markdown parsing.

## Consequences
* ✅ **Positive:** Zero operational cost for the MVP.
* ✅ **Positive:** Provider-agnostic code. Switching to GPT-4 involves changing a single import line.
* ✅ **Positive:** Guaranteed valid JSON responses thanks to Zod validation.
* ⚠️ **Neutral:** Dependency on an external library (`ai`), though it is currently an industry standard.
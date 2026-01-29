# ADR 0003: Continuous Deployment on Render

* **Status:** Accepted
* **Date:** 2026-01-26

## Context
We need a deployment platform supporting Node.js and PostgreSQL, with zero or very low cost for the MVP, allowing automatic CI/CD from GitHub.

## Decision
Use **Render** (Free Tier).
* **Auto-Deploy:** Automatic trigger upon pushing to `main`.
* **Database:** PostgreSQL managed by Render.

## Consequences
* ✅ **Positive:** Near-zero configuration ("Zero Ops").
* ❌ **Negative:** The free tier puts the service to "sleep" after inactivity (slow cold starts).
* ❌ **Negative:** No SSH (Shell) access in the free tier.
    * *Mitigation:* Shell commands were executed via the `Build Command` to resolve migration conflicts (`prisma migrate resolve`).
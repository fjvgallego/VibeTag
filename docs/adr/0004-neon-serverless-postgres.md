# ADR 0004: Serverless Database with Neon

* **Status:** Accepted
* **Date:** 2026-01-26

## Context
While Render handles our application hosting effectively, its free-tier PostgreSQL database has significant limitations for a persistent project: it expires after 30 days and lacks advanced features like branching or autoscaling.

## Decision
Use **Neon** as the primary PostgreSQL provider.
* **Architecture:** Serverless PostgreSQL (Separation of storage and compute).
* **Integration:** Connected to the Render backend via standard connection strings (Pooled).

## Consequences
* ✅ **Positive:** **Permanence.** Unlike Render's free-tier, Neon's free tier does not expire the database.
* ✅ **Positive:** **Database Branching.** Allows creating instant, copy-on-write clones of the database for testing or development without duplicating data manually.
* ✅ **Positive:** **Scale-to-Zero.** Compute suspends when inactive to save costs (though this may introduce cold starts).
* ⚠️ **Neutral:** **Network Latency.** The database (Neon) and Application (Render) are on different clouds. We must ensure both are provisioned in the same region (e.g., Frankfurt/Germany) to minimize latency.
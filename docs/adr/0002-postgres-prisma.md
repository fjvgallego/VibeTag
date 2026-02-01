# ADR 0002: Persistence with PostgreSQL and Prisma

* **Status:** Accepted
* **Date:** 2026-01-25

## Context
We require a relational database to manage structured relationships (Users <-> Analyses <-> Songs). We need full Type Safety across the backend to reduce runtime errors.

## Decision
Use **PostgreSQL** as the database engine and **Prisma ORM** for interaction.

## Consequences
* ✅ **Positive:** Automatic static typing generated from `schema.prisma`.
* ✅ **Positive:** Robust migration management (`prisma migrate`).
* ⚠️ **Neutral:** Necessity to manage "Connection Pooling" in Serverless/Cloud environments.
* ⚠️ **Neutral:** Dependency on the Prisma binary during deployment (requires client regeneration in `postinstall`).
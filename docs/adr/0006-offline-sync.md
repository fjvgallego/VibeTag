# ADR-0006: Offline Synchronization Strategy (Dirty Flags & Optimistic UI)

* **Status:** Accepted
* **Date:** 2026-02-01

## Context and Problem Statement
Users need the ability to manage song tags and metadata regardless of their network connection status. Currently, the application relies on a remote Backend (PostgreSQL) as the source of truth, but data is also persisted locally using SwiftData.

We faced the following challenges:
1.  **Offline Editing:** Users must be able to add, edit, or delete tags while offline (e.g., on a plane or subway).
2.  **UX Latency:** Waiting for a server response to confirm a simple tag edit creates a sluggish user experience.
3.  **Data Consistency:** We need a mechanism to identify which local changes have not yet been propagated to the backend once connectivity is restored.

We agreed that for the current scope (Sprint 3), local data in SwiftData acts as the temporary source of truth during offline sessions.

## Decision Drivers
* Need for a seamless, non-blocking user experience (Optimistic UI).
* Need to minimize bandwidth usage (only sync changed items).
* Complexity reduction: Avoiding complex conflict resolution algorithms (CRDTs) for this project phase.

## Considered Options
1.  **Full State Comparison:** Compare the entire local database against the remote database upon reconnection.
    * *Pros:* Robust.
    * *Cons:* High bandwidth usage, slow processing time, computationally expensive.
2.  **Blocking UI:** Disable editing features when the device is offline.
    * *Pros:* Guarantees consistency.
    * *Cons:* Poor User Experience.
3.  **Dirty Flags + Optimistic UI:** Mark specific records as "modified" locally and sync only those records.
    * *Pros:* Efficient, instant feedback for the user.
    * *Cons:* Requires state management in the local repository.

## Decision
We have decided to implement the **Dirty Flag Pattern** combined with **Optimistic UI**.

We will introduce a synchronization state field to the local persistent model (SwiftData). When a user modifies data, the UI updates immediately, and the record is marked as "pending". A background sync engine will process these pending records when the network is available.

### Technical Implementation

1.  **Model Update:**
    The `VTSong` (or equivalent SwiftData entity) will include a new property `syncStatus`.

    ```swift
    enum SyncStatus: Int, Codable {
        case synced = 0         // Data matches the backend
        case pendingUpload = 1  // Modified locally, needs to be sent to server
        case pendingDelete = 2  // Deleted locally, backend needs to be notified
    }
    ```

2.  **Workflow:**
    * **User Action:** User edits a tag.
    * **Local Repo:** Saves changes to SwiftData and sets `syncStatus = .pendingUpload`.
    * **Sync Engine:**
        * Monitors network connectivity.
        * Queries SwiftData for all items where `syncStatus != .synced`.
        * Iterates through items and calls the respective API endpoints.
        * Upon `200 OK` response, updates the local item to `syncStatus = .synced`.

3.  **Conflict Resolution:**
    For this phase, we adopt a **"Client Wins" / "Last Write Wins"** strategy for upstream changes. The local modification is assumed to be the most relevant user intent.

## Consequences

### Positive
* **User Experience:** The app feels instant. No loading spinners for simple tag edits.
* **Efficiency:** We only transmit data that has actually changed.
* **Resilience:** The app is fully functional offline.

### Negative
* **Concurrency Risk:** If a user edits the same song on two different offline devices, the last one to sync will overwrite the previous one. This is an accepted risk for the current MVP.
* **Maintenance:** The `LocalSongRepository` must strictly manage state transitions to avoid data inconsistencies.
# VibeTag iOS Architecture

This document outlines the architectural patterns, directory structure, and programming guidelines used in the VibeTag iOS application. 

The app follows a **Clean Architecture** approach combined with **MVVM (Model-View-ViewModel)** for the Presentation layer, ensuring separation of concerns, testability, and high scalability.

## 🏗 Directory Structure & Layers

### 1. Presentation Layer
Responsible for rendering the UI and handling user interactions. ViewModels act as the bridge between the Views and the Domain layer. 
*(Note: ViewModels utilize the new Swift 6 `@Observable` macro and are strictly bound to the `@MainActor`).*

* **`Features/`** — Organized by feature/screen. Each folder represents a distinct functional area containing its `*View.swift` and `*ViewModel.swift`.
  * **`[Feature]/Views/`** — Sub-components or specific views strictly unique to this feature.
  * **`/Root`** — The entry point of the app. Handles the main navigation stack, orchestrates the authentication flow (anonymous vs. authenticated user), and initializes data containers.
* **`Sheets/`** — Dedicated folder for modal presentations (Bottom Sheets). Each sheet lives in its own named subfolder (e.g., `Sheets/TagAssignment/`) containing `*Sheet.swift` and, when complex logic is required, a co-located `*ViewModel.swift`.
* **`Components/`** — Reusable, generic UI building blocks shared across multiple features.
  * **`/Controls`** — Standardized app controls (primary buttons, custom segmented controls, text fields).
  * **`/Views`** — Shared visual components (e.g., floating bars, generic song rows, lists).

### 2. Domain Layer
The heart of the application. It contains the core business rules and is entirely independent of the UI or external frameworks (Data/Network).

* **`Models/`** — The pure data entities representing the business domain (e.g., `VTSong`, `Tag`, `SyncStatus`).
* **`UseCases/`** — Encapsulate a single, specific business responsibility (e.g., `AnalyzeSongUseCase`). They orchestrate logic by calling one or more repositories.
* **`Interfaces/`** — The contracts (Protocols) that external layers must fulfill. Crucial for Dependency Inversion. Contains definitions for Repositories and Services (domain-level contracts only, e.g., `SyncEngine`, `LibraryImportSyncService`). Infrastructure-specific protocols (e.g., `APIClientProtocol`, `NetworkMonitorProtocol`) live in Core next to their implementations.
* **`Errors/`** — Centralized domain-level error definitions (`AppError.swift`) that will be propagated and handled by the presentation layer.

### 3. Core / Data Layer (Infrastructure)
This layer implements the interfaces defined in the Domain. It is responsible for external communications (Network, Local Database, Apple Music API).

* **`DI/`** — Dependency Injection setup (`AppContainer`). Initializes and provides all dependencies.
* **`Data/`** — Concrete implementations of data sources.
  * **`/Networking`** — `APIClient` (URLSession wrapper), `APIError`, `APIClientProtocol`.
    * **`/DTOs`** — Data Transfer Objects. One dedicated file/folder per request and response (e.g., `AnalyzeRequestDTO`).
    * **`/Endpoints`** — Base `Endpoint.swift` protocol and structured enum files for each API domain (`PlaylistEndpoint`, `AuthEndpoint`).
  * **`/Repositories`** — Concrete implementations of the domain repository interfaces (e.g., SwiftData storage, MusicKit fetches, Backend Sync).
  * **`/Storage`** — Device-level persistence (e.g., `KeychainTokenStorage`).
* **`Services/`** — Background orchestrators, system state providers, and their protocols (e.g., `VibeTagSyncEngine`, `AppleMusicLibraryImportService`, `SessionManager`, `NetworkMonitor`, `NetworkMonitorProtocol`). The distinction between "service" and "manager" is intentionally collapsed here — if it isn't a Repository, it lives in `Services/`.
* **`Navigation/`** — Routing architecture (`AppRouter` using `@Observable` for programmatic navigation).
* **`Extensions/` & `Helpers/` & `Design/`** — Utilities, SwiftUI modifiers, custom layouts (e.g., `TagFlowLayout`), and Swift language extensions.
* **`Configuration/`** — Environment variables and feature flags.

---

## 🔄 Data Flow (How layers interact)

To maintain a clean boundary, the data strictly flows as follows:

1. **API/Database ➔ Repository**: The `APIClient` fetches a **DTO**. The `Repository` maps this DTO into a pure **Domain Model** (`VTSong`).
2. **Repository ➔ Use Case**: The `UseCase` requests **Domain Models** from the `Repository` interface (ignoring if it comes from SwiftData or the Backend).
3. **Use Case ➔ ViewModel**: The `ViewModel` executes the `UseCase`, receives the result (or error), and mutates its `@Observable` state.
4. **ViewModel ➔ View**: The `View` automatically re-renders based on the ViewModel's state changes.

---

## 💻 iOS Programming Guidelines & Standards

This codebase strictly adheres to modern iOS development standards:

* **Swift 6 Concurrency:** Extensive use of `async/await`. Strict concurrency checking is enabled. UI state mutations are isolated using `@MainActor`, and data-passing utilizes `Sendable` types.
* **SOLID Principles:** Classes and structs have a single responsibility. Dependencies are injected via protocols (Dependency Inversion).
* **Clean Architecture:** Inner layers (Domain) never import or depend on outer layers (Core/UI).
* **Offline-First (Optimistic UI):** SwiftData acts as the Single Source of Truth. The UI reads from local storage instantly, while background services (`SyncEngine`) handle API synchronization to ensure a snappy user experience.
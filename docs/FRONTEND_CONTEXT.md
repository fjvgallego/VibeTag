# VibeTag: iOS Technical Context

## Tech Stack
- **Language:** Swift 6.
- **UI Framework:** SwiftUI.
- **Architecture:** MVVM-C (Coordinators) or simplified Clean Architecture.
- **Persistence:** SwiftData (Acts as the Single Source of Truth).
- **Core Frameworks:** `MusicKit`, `NaturalLanguage`, `AuthenticationServices`, `BackgroundTasks`.

## Engineering Principles
1. **Offline-First:** The UI **always** reads from SwiftData. Never fetch from the Backend API directly for UI display.
2. **Synchronization:** Data sync happens in the background to avoid blocking the main thread.
3. **Concurrency:** Strict usage of `async/await` and Actors to ensure data safety.
4. **Design Implementation:** Strict adherence to `design_system.md`, using modern SwiftUI modifiers (`.background(.ultraThinMaterial)`, `MeshGradient`, etc.).
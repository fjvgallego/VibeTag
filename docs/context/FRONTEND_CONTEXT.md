# VibeTag: iOS Technical Context

## Tech Stack
- **Language:** Swift 6.
- **UI Framework:** SwiftUI.
- **Architecture:** MVVM + Router Pattern (Feature-Based Grouping).
- **Persistence:** SwiftData.

## Project Structure (Layered & Feature-Based)
We organize code by **Layer** and **Feature** to maintain clear boundaries.
- **`App/`**: Entry point (`VibeTagApp.swift`) and App-level configuration.
- **`Features/`**: UI logic and views grouped by functional area.
  - **`Root/`**: Main container (`RootView`, `RootViewModel`, `WelcomeView`).
  - **`Home/`**: Dashboard logic (`HomeView`, `HomeViewModel`).
  - **`Login/`**: SIWA implementation (`LoginView`, `LoginViewModel`).
  - **`SongDetail/`**: Detailed view of a song and its tags.
  - **`Tags/`**: Tag selection and creation sheets.
- **`Domain/`**: Pure business logic and entities.
  - **`Models/`**: SwiftData entities (`VTSong.swift`, `Tag.swift`).
  - **`UseCases/`**: Single-responsibility business actions (`AnalyzeSongUseCase.swift`).
  - **`Interfaces/`**: Protocol definitions for services and repositories.
- **`Core/`**: Infrastructure and shared utilities.
  - **`Data/`**: Concrete implementations of repositories (Networking, Storage, SwiftData).
  - **`Services/`**: System-level services (`MusicSyncService.swift`).
  - **`Navigation/`**: Centralized routing logic (`AppRouter.swift`).
  - **`Managers/`**: Global state managers (`SessionManager.swift`).

## Data Models (SwiftData)
### 1. Song (`Domain/Models/VTSong.swift`)
- **`id`**: `String` (Unique Identifier).
  - **Canonical Behavior:** Prefer **ISRC** (International Standard Recording Code) when available for better cross-platform matching. Fall back to **Apple Music ID** (Catalog ID) if ISRC is missing.
  - **Validation:**
    - **ISRC:** 12 alphanumeric characters (e.g., `"US-S1Z-99-00001"` or `"USS1Z9900001"`).
    - **Apple Music ID:** Numeric string (e.g., `"1488408568"`).

- **`title`**, **`artist`**, **`artworkUrl`**.
- **`tags`**: Relationship to `Tag`.
- **`dateAdded`**: `Date` (Timestamp when the song was added).
- **`syncStatus`**: `SyncStatus` (Sync state tracking for cloud synchronization, implemented as a computed property backed by `syncStatusRaw: Int`).

### 2. Tag (`Domain/Models/Tag.swift`)
- **`id`**: `UUID`.
- **`name`** (Unique), **`hexColor`**.
- **`isSystemTag`**: `Bool`.
  - **Purpose:** Identifies application-defined tags (e.g., "Favorites", "Recent") versus user-created ones.
  - **Mutability:** **Immutable**. System tags cannot be renamed or deleted by the user.
  - **UI Treatment:** Displayed with a distinct visual indicator (e.g., specific icon or badge). Edit/Delete controls are disabled/hidden in the UI.
- **`songs`**: Relationship to `VTSong`.

## Engineering Principles
1. **Unidirectional Data Flow:** Views trigger actions in ViewModels, which interact with Use Cases.
2. **Offline-First:** SwiftData serves as the single source of truth for the UI.
3. **Clean Architecture:** Use Cases decouple UI from data sources.
4. **Router Pattern:** Navigation state is managed by an observable router.

## 🛡️ Coding Guidelines (The "Rules of Engagement")

### 1. Architecture: Strict MVVM
- **Views are "Dumb":** They only render state. They NEVER calculate logic or make API calls directly.
- **ViewModels are the Brains:** All business logic, state manipulation, and calls to Services happen here.
- **Services are Worker Bees:** They handle data fetching (MusicKit, API) and return raw data. They do not know about UI.

### 2. Clean Code & SOLID
- **Single Responsibility:** A View should do one thing. If a View exceeds 200 lines, extract sub-views.
- **Dependency Injection:** Inject Services into ViewModels (via init) rather than calling Singletons directly inside methods. This makes testing easier.
- **Formatting:** Adhere to standard SwiftLint rules. 

### 3. Swift Specifics
- **Concurrency:** Use `async/await` over completion handlers.
- **Main Thread:** Always ensure UI updates happen on `@MainActor`.
- **Naming:** - generally avoid prefixes (e.g., `HomeView`, not `VTHomeView`).
  - **EXCEPTION:** Use `VT` prefix for Data Models that collide with SDK types (specifically `VTSong` to avoid conflict with `MusicKit.Song`).

## 🛡️ Security Standards (OWASP MASVS)
**Principle:** Data Privacy & Secure Storage.

1.  **Insecure Data Storage (MASVS-STORAGE):**
    - **Rule:** Never store sensitive data in `UserDefaults` or `SwiftData`.
    - **Implementation:**
        - **Tokens/Auth:** MUST be stored in the **Keychain** (use a wrapper like `Valet` or `KeychainAccess`).
        - **User Content:** `SwiftData` is for non-sensitive content (Songs, Tags) only.

2.  **Insecure Communication (MASVS-NETWORK):**
    - **Rule:** Strict Transport Security.
    - **Implementation:** All network calls must use **HTTPS**. Do not allow arbitrary loads (`NSAppTransportSecurity` exceptions) unless hitting `localhost` for debug.

3.  **Extraneous Functionality (Logs):**
    - **Rule:** No sensitive data in logs.
    - **Implementation:** Do not use `print()` for API tokens, User IDs, or PII. Use `OSLog` with `.private` redaction if necessary.

4.  **Code Quality (Hardcoding):**
    - **Rule:** No Secrets in Code.
    - **Implementation:** API Keys and Secrets must be injected via `.xcconfig` or Environment Variables, never hardcoded in Swift files committed to Git.
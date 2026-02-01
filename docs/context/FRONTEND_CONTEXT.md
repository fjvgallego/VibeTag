# VibeTag: iOS Technical Context

## Tech Stack
- **Language:** Swift 6.
- **UI Framework:** SwiftUI.
- **Architecture:** MVVM + Router Pattern (Feature-Based Grouping).
- **Persistence:** SwiftData.

## Project Structure (Feature-Based)
We organize code by **Feature**, not by file type.
- **`App/`**: Entry point (`VibeTagApp.swift`).
- **`Features/`**:
  - **`Root/`**: Main container (`RootView`, `RootViewModel`).
  - **`Home/`**: Dashboard logic (`HomeView`, `HomeViewModel`).
  - *Future features (e.g., `Library`, `Settings`) go here.*
- **`Shared/`**:
  - **`Models/`**: SwiftData entities (`Song.swift`, `Tag.swift`).
  - **`Services/`**: Singletons & Logic (`MusicKitService`, `APIService`).
  - **`Navigation/`**: `AppRouter`.

## Data Models (SwiftData)
### 1. Song (`Shared/Models/Song.swift`)
- **`id`**: `String` (Unique).
- **`title`**, **`artist`**, **`artworkUrl`**.
- **`tags`**: Relationship to `Tag`.

### 2. Tag (`Shared/Models/Tag.swift`)
- **`id`**: `UUID`.
- **`name`** (Unique), **`hexColor`**.
- **`songs`**: Relationship to `Song`.

## Engineering Principles
1. **Colocation:** Views and their ViewModels live in the same Feature folder.
2. **Offline-First:** UI reads from SwiftData.
3. **Router Pattern:** Navigation state is managed by an observable router, not hardcoded links.

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
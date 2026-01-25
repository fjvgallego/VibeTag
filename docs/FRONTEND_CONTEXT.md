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
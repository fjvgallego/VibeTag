# VibeTag iOS — Testing Patterns

## SwiftData in tests
- Always wrap `ModelContainer`, `ModelContext`, and `LocalSongStorageRepositoryImpl` in a struct (`Env`) so the container is not discarded early.
- `_` in a tuple binding (`let (a, b, _) = ...`) discards the value **immediately**, not at end of scope — causes `EXC_BAD_ACCESS` for SwiftData objects.

## Fire-and-forget Tasks (ViewModels)
- `analyzeSong`, `addTag`, `removeTag` in `SongDetailViewModel` spawn `Task {}` internally.
- Use `drainTasks()` with **6 x `Task.yield()`** after calling these methods — 3 was not enough for paths with `await MainActor.run {}`.

## Protocols extracted during testing
- `NetworkMonitorProtocol` — extracted so `MockNetworkMonitor` can control `isConnected`.
- `APIClientProtocol` — extracted so `MockAPIClient` can stub network calls in `VibeTagSyncEngine`.
- Both protocols are `@MainActor`.

## Production changes made alongside tests
- `VibeTagSyncEngine`: injects `NetworkMonitorProtocol` + `APIClientProtocol` (defaults preserve call sites).
- `HomeViewModel`: injects `LibraryImportSyncService?` (optional, nil default); `performFullSync` accepts `any SyncEngine` instead of concrete `VibeTagSyncEngine`.
- `SettingsViewModel`: same `performFullSync` signature fix.
- `CreatePlaylistViewModel`: init accepts `GeneratePlaylistUseCaseProtocol` instead of concrete class; fixed whitespace-only prompt bug in guard.

## Test file locations
```
VibeTagTests/
  Mocks/
    MockSongRepository.swift
    MockSongStorageRepository.swift       ← also tracks fetchAllSongs, fetchPendingUploads, markAsSynced, hydrateRemoteTags
    MockNetworkMonitor.swift
    MockAPIClient.swift
    MockTokenStorage.swift
    MockAuthRepository.swift
    MockSyncEngine.swift
    MockAnalyzeSongUseCase.swift           ← supports executeBatch progress simulation + throw
    MockLibraryImportSyncService.swift
    MockGeneratePlaylistUseCase.swift
    MockExportPlaylistUseCase.swift
  Repositories/
    LocalSongStorageRepositoryTests.swift  ← uses real in-memory SwiftData container via Env struct
  UseCases/
    AnalyzeSongUseCaseTests.swift
  Services/
    VibeTagSyncEngineTests.swift
  ViewModels/
    SongDetailViewModelTests.swift
    HomeViewModelTests.swift
    CreatePlaylistViewModelTests.swift
```

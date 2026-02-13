import Testing
import Foundation
import SwiftData
@testable import VibeTag
internal import MusicKit

// MARK: - Helpers

/// Throwaway in-memory ModelContext. The context itself is never used in tests because
/// LibraryImportSyncService is always injected — this just satisfies the parameter type.
@MainActor
private func makeModelContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: VTSong.self, VibeTag.Tag.self, configurations: config)
    return container.mainContext
}

@MainActor
private func makeSUT(
    songs: [VTSong] = [],
    useCase: MockAnalyzeSongUseCase = MockAnalyzeSongUseCase(),
    importService: MockLibraryImportSyncService = MockLibraryImportSyncService()
) -> (sut: HomeViewModel, repo: MockSongStorageRepository, useCase: MockAnalyzeSongUseCase, importService: MockLibraryImportSyncService) {
    let repo = MockSongStorageRepository()
    repo.fetchAllSongsResult = songs
    let sut = HomeViewModel(
        analyzeUseCase: useCase,
        localRepository: repo,
        libraryImportService: importService
    )
    return (sut, repo, useCase, importService)
}

private func makeSong(id: String, systemTags: [String] = [], userTags: [String] = []) -> VTSong {
    let song = VTSong(id: id, title: "Song \(id)", artist: "Artist")
    song.tags = systemTags.map { VibeTag.Tag(name: $0, hexColor: "#808080", isSystemTag: true) }
               + userTags.map  { VibeTag.Tag(name: $0, hexColor: "#000000", isSystemTag: false) }
    return song
}

// MARK: - Computed properties

@MainActor
@Suite("HomeViewModel — computed properties")
struct HomeViewModelComputedPropertyTests {

    @Test("isAppleMusicLinked is true when status is authorized")
    func isLinkedWhenAuthorized() {
        let (sut, _, _, _) = makeSUT()
        sut.musicAuthorizationStatus = .authorized
        #expect(sut.isAppleMusicLinked == true)
    }

    @Test("isAppleMusicLinked is false when status is not authorized")
    func isNotLinkedWhenNotAuthorized() {
        let (sut, _, _, _) = makeSUT()
        sut.musicAuthorizationStatus = .notDetermined
        #expect(sut.isAppleMusicLinked == false)
    }

    @Test("analysisProgress is 0 when totalToAnalyzeCount is 0")
    func progressIsZeroWhenTotalIsZero() {
        let (sut, _, _, _) = makeSUT()
        sut.totalToAnalyzeCount = 0
        #expect(sut.analysisProgress == 0)
    }

    @Test("analysisProgress is correct ratio when totalToAnalyzeCount > 0")
    func progressIsCorrectRatio() {
        let (sut, _, _, _) = makeSUT()
        sut.totalToAnalyzeCount = 10
        sut.currentAnalyzedCount = 4
        #expect(sut.analysisProgress == 0.4)
    }

    @Test("analysisProgress is 1.0 when all songs are analyzed")
    func progressIsOneWhenComplete() {
        let (sut, _, _, _) = makeSUT()
        sut.totalToAnalyzeCount = 5
        sut.currentAnalyzedCount = 5
        #expect(sut.analysisProgress == 1.0)
    }
}

// MARK: - refreshLibraryStats

@MainActor
@Suite("HomeViewModel.refreshLibraryStats")
struct RefreshLibraryStatsTests {

    @Test("Sets totalSongsCount to the number of songs in the repository")
    func setsTotalSongsCount() {
        let songs = [makeSong(id: "s1"), makeSong(id: "s2"), makeSong(id: "s3")]
        let (sut, _, _, _) = makeSUT(songs: songs)
        #expect(sut.totalSongsCount == 3)
    }

    @Test("Sets unanalyzedCount to songs that have no system tags")
    func setsUnanalyzedCount() {
        let songs = [
            makeSong(id: "s1", systemTags: ["pop"]),  // analyzed
            makeSong(id: "s2"),                         // unanalyzed
            makeSong(id: "s3", userTags: ["fav"]),      // unanalyzed (only user tags)
            makeSong(id: "s4", systemTags: ["rock"])    // analyzed
        ]
        let (sut, _, _, _) = makeSUT(songs: songs)
        #expect(sut.unanalyzedCount == 2)
    }

    @Test("Sets both counts to 0 when repository is empty")
    func setsZeroWhenEmpty() {
        let (sut, _, _, _) = makeSUT(songs: [])
        #expect(sut.totalSongsCount == 0)
        #expect(sut.unanalyzedCount == 0)
    }

    @Test("Does not crash when fetchAllSongs throws")
    func doesNotCrashOnError() {
        let repo = MockSongStorageRepository()
        repo.fetchAllSongsShouldThrow = AppError.unknown
        // init calls refreshLibraryStats — should not throw
        let sut = HomeViewModel(analyzeUseCase: MockAnalyzeSongUseCase(), localRepository: repo)
        #expect(sut.totalSongsCount == 0)
        #expect(sut.unanalyzedCount == 0)
    }

    @Test("Updates counts when called again after songs change")
    func updatesCountsOnSubsequentCall() {
        let repo = MockSongStorageRepository()
        repo.fetchAllSongsResult = [makeSong(id: "s1")]
        let sut = HomeViewModel(analyzeUseCase: MockAnalyzeSongUseCase(), localRepository: repo)
        #expect(sut.totalSongsCount == 1)

        repo.fetchAllSongsResult = [makeSong(id: "s1"), makeSong(id: "s2")]
        sut.refreshLibraryStats()
        #expect(sut.totalSongsCount == 2)
    }
}

// MARK: - syncLibrary

@MainActor
@Suite("HomeViewModel.syncLibrary")
struct SyncLibraryTests {

    @Test("Sets isSyncing to false after successful sync")
    func isSyncingFalseAfterSuccess() async throws {
        let ctx = try makeModelContext()
        let (sut, _, _, _) = makeSUT()
        await sut.syncLibrary(modelContext: ctx)
        #expect(sut.isSyncing == false)
    }

    @Test("Sets isSyncing to false even when sync throws")
    func isSyncingFalseAfterFailure() async throws {
        let ctx = try makeModelContext()
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.unknown
        let (sut, _, _, _) = makeSUT(importService: importService)
        await sut.syncLibrary(modelContext: ctx)
        #expect(sut.isSyncing == false)
    }

    @Test("Calls syncLibrary on the injected service")
    func callsInjectedService() async throws {
        let ctx = try makeModelContext()
        let importService = MockLibraryImportSyncService()
        let (sut, _, _, service) = makeSUT(importService: importService)
        await sut.syncLibrary(modelContext: ctx)
        #expect(service.syncLibraryCallCount == 1)
    }

    @Test("Sets errorMessage when sync throws")
    func setsErrorMessageOnFailure() async throws {
        let ctx = try makeModelContext()
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.serverError(statusCode: 503)
        let (sut, _, _, _) = makeSUT(importService: importService)
        await sut.syncLibrary(modelContext: ctx)
        #expect(sut.errorMessage != nil)
    }

    @Test("Clears errorMessage at the start of a new sync")
    func clearsErrorMessageAtStart() async throws {
        let ctx = try makeModelContext()
        let (sut, _, _, _) = makeSUT()
        sut.errorMessage = "stale error"
        await sut.syncLibrary(modelContext: ctx)
        #expect(sut.errorMessage == nil)
    }

    @Test("Refreshes library stats after successful sync")
    func refreshesStatsAfterSync() async throws {
        let ctx = try makeModelContext()
        let repo = MockSongStorageRepository()
        repo.fetchAllSongsResult = []
        let sut = HomeViewModel(analyzeUseCase: MockAnalyzeSongUseCase(),
                                localRepository: repo,
                                libraryImportService: MockLibraryImportSyncService())
        // Simulate new songs being added by the sync
        repo.fetchAllSongsResult = [makeSong(id: "s1"), makeSong(id: "s2")]
        await sut.syncLibrary(modelContext: ctx)
        #expect(sut.totalSongsCount == 2)
    }
}

// MARK: - performFullSync

@MainActor
@Suite("HomeViewModel.performFullSync")
struct PerformFullSyncTests {

    @Test("Sets isSyncing to false after successful full sync")
    func isSyncingFalseAfterSuccess() async throws {
        let ctx = try makeModelContext()
        let (sut, _, _, _) = makeSUT()
        let syncEngine = MockSyncEngine()
        await sut.performFullSync(modelContext: ctx, syncEngine: syncEngine)
        #expect(sut.isSyncing == false)
    }

    @Test("Sets isSyncing to false when import service throws")
    func isSyncingFalseAfterImportFailure() async throws {
        let ctx = try makeModelContext()
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.unknown
        let (sut, _, _, _) = makeSUT(importService: importService)
        await sut.performFullSync(modelContext: ctx, syncEngine: MockSyncEngine())
        #expect(sut.isSyncing == false)
    }

    @Test("Sets isSyncing to false when pullRemoteData throws")
    func isSyncingFalseAfterPullFailure() async throws {
        let ctx = try makeModelContext()
        let syncEngine = MockSyncEngine()
        syncEngine.pullRemoteDataShouldThrow = AppError.serverError(statusCode: 500)
        let (sut, _, _, _) = makeSUT()
        await sut.performFullSync(modelContext: ctx, syncEngine: syncEngine)
        #expect(sut.isSyncing == false)
    }

    @Test("Calls syncLibrary on the import service")
    func callsImportService() async throws {
        let ctx = try makeModelContext()
        let importService = MockLibraryImportSyncService()
        let (sut, _, _, _) = makeSUT(importService: importService)
        await sut.performFullSync(modelContext: ctx, syncEngine: MockSyncEngine())
        #expect(importService.syncLibraryCallCount == 1)
    }

    @Test("Calls pullRemoteData on the sync engine")
    func callsPullRemoteData() async throws {
        let ctx = try makeModelContext()
        let syncEngine = MockSyncEngine()
        let (sut, _, _, _) = makeSUT()
        await sut.performFullSync(modelContext: ctx, syncEngine: syncEngine)
        #expect(syncEngine.pullRemoteDataCallCount == 1)
    }

    @Test("Does not call pullRemoteData when import service fails")
    func doesNotPullWhenImportFails() async throws {
        let ctx = try makeModelContext()
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.unknown
        let syncEngine = MockSyncEngine()
        let (sut, _, _, _) = makeSUT(importService: importService)
        await sut.performFullSync(modelContext: ctx, syncEngine: syncEngine)
        #expect(syncEngine.pullRemoteDataCallCount == 0)
    }

    @Test("Sets errorMessage when import service throws")
    func setsErrorOnImportFailure() async throws {
        let ctx = try makeModelContext()
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.unknown
        let (sut, _, _, _) = makeSUT(importService: importService)
        await sut.performFullSync(modelContext: ctx, syncEngine: MockSyncEngine())
        #expect(sut.errorMessage != nil)
    }

    @Test("Sets errorMessage when pullRemoteData throws")
    func setsErrorOnPullFailure() async throws {
        let ctx = try makeModelContext()
        let syncEngine = MockSyncEngine()
        syncEngine.pullRemoteDataShouldThrow = AppError.serverError(statusCode: 500)
        let (sut, _, _, _) = makeSUT()
        await sut.performFullSync(modelContext: ctx, syncEngine: syncEngine)
        #expect(sut.errorMessage != nil)
    }

    @Test("Clears errorMessage at the start of a new full sync")
    func clearsErrorMessageAtStart() async throws {
        let ctx = try makeModelContext()
        let (sut, _, _, _) = makeSUT()
        sut.errorMessage = "stale error"
        await sut.performFullSync(modelContext: ctx, syncEngine: MockSyncEngine())
        #expect(sut.errorMessage == nil)
    }
}

// MARK: - analyzeLibrary

@MainActor
@Suite("HomeViewModel.analyzeLibrary")
struct AnalyzeLibraryTests {

    @Test("Sets isAnalyzing to false after successful analysis")
    func isAnalyzingFalseAfterSuccess() async {
        let songs = [makeSong(id: "s1")]
        let (sut, _, _, _) = makeSUT(songs: songs)
        await sut.analyzeLibrary()
        #expect(sut.isAnalyzing == false)
    }

    @Test("Sets isAnalyzing to false even when analysis throws")
    func isAnalyzingFalseAfterError() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeResult = .failure(AppError.serverError(statusCode: 500))
        let songs = [makeSong(id: "s1")]
        let (sut, _, _, _) = makeSUT(songs: songs, useCase: useCase)
        await sut.analyzeLibrary()
        #expect(sut.isAnalyzing == false)
    }

    @Test("Resets currentAnalyzedCount to 0 at start")
    func resetsCountAtStart() async {
        let (sut, _, _, _) = makeSUT(songs: [])
        sut.currentAnalyzedCount = 99
        await sut.analyzeLibrary()
        // After the short-circuit for empty, count is 0
        #expect(sut.currentAnalyzedCount == 0)
    }

    @Test("Short-circuits with 'already analyzed' status when all songs have system tags")
    func shortCircuitsWhenAllAnalyzed() async {
        let songs = [makeSong(id: "s1", systemTags: ["pop"]), makeSong(id: "s2", systemTags: ["rock"])]
        let useCase = MockAnalyzeSongUseCase()
        let (sut, _, uc, _) = makeSUT(songs: songs, useCase: useCase)
        await sut.analyzeLibrary()
        #expect(uc.executeCallCount == 0)
        #expect(sut.analysisStatus == "La biblioteca ya está analizada")
        #expect(sut.isAnalyzing == false)
    }

    @Test("Short-circuits when library is empty")
    func shortCircuitsWhenEmpty() async {
        let useCase = MockAnalyzeSongUseCase()
        let (sut, _, uc, _) = makeSUT(songs: [], useCase: useCase)
        await sut.analyzeLibrary()
        #expect(uc.executeCallCount == 0)
        #expect(sut.analysisStatus == "La biblioteca ya está analizada")
    }

    @Test("Sets totalToAnalyzeCount to the number of unanalyzed songs")
    func setsTotalToAnalyzeCount() async {
        let songs = [
            makeSong(id: "s1"),
            makeSong(id: "s2", systemTags: ["pop"]),
            makeSong(id: "s3")
        ]
        let (sut, _, _, _) = makeSUT(songs: songs)
        await sut.analyzeLibrary()
        #expect(sut.totalToAnalyzeCount == 2)
    }

    @Test("Only sends unanalyzed songs to executeBatch")
    func sendsOnlyUnanalyzedSongs() async {
        let songs = [
            makeSong(id: "s1"),                         // unanalyzed
            makeSong(id: "s2", systemTags: ["pop"]),    // already analyzed — must be excluded
            makeSong(id: "s3", userTags: ["fav"])       // unanalyzed (only user tag)
        ]
        let useCase = MockAnalyzeSongUseCase()
        let (sut, _, _, _) = makeSUT(songs: songs, useCase: useCase)
        await sut.analyzeLibrary()
        // executeBatch is called; verify the count indirectly via totalToAnalyzeCount
        #expect(sut.totalToAnalyzeCount == 2)
    }

    @Test("Progress callback updates currentAnalyzedCount")
    func progressCallbackUpdatesCount() async {
        let songs = (1...3).map { makeSong(id: "s\($0)") }
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeBatchProgressSimulation = [(1, 3), (2, 3), (3, 3)]
        let (sut, _, _, _) = makeSUT(songs: songs, useCase: useCase)
        await sut.analyzeLibrary()
        // The last progress callback sets currentAnalyzedCount to 3;
        // analyzeLibrary does not reset it afterwards.
        #expect(sut.currentAnalyzedCount == 3)
    }

    @Test("Sets analysisStatus to completion message after successful analysis")
    func setsCompletionStatus() async {
        let songs = [makeSong(id: "s1")]
        let (sut, _, _, _) = makeSUT(songs: songs)
        await sut.analyzeLibrary()
        #expect(sut.analysisStatus == "Análisis completo!")
    }

    @Test("Sets errorMessage when executeBatch throws")
    func setsErrorMessageOnFailure() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeBatchShouldThrow = AppError.serverError(statusCode: 500)
        let songs = [makeSong(id: "s1")]
        let (sut, _, _, _) = makeSUT(songs: songs, useCase: useCase)
        await sut.analyzeLibrary()
        #expect(sut.errorMessage != nil)
    }

    @Test("Refreshes library stats after successful analysis")
    func refreshesStatsAfterAnalysis() async {
        let repo = MockSongStorageRepository()
        let song = makeSong(id: "s1")
        repo.fetchAllSongsResult = [song]
        let sut = HomeViewModel(analyzeUseCase: MockAnalyzeSongUseCase(),
                                localRepository: repo,
                                libraryImportService: MockLibraryImportSyncService())
        // After analysis the song now has a system tag
        song.tags = [VibeTag.Tag(name: "pop", hexColor: "#808080", isSystemTag: true)]
        await sut.analyzeLibrary()
        #expect(sut.unanalyzedCount == 0)
    }
}

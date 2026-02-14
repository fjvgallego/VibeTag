import Testing
import Foundation
@testable import VibeTag

// MARK: - Helpers

@MainActor
private func makeSUT(
    songs: [VTSong] = [],
    importService: MockLibraryImportSyncService = MockLibraryImportSyncService(),
    syncEngine: MockSyncEngine = MockSyncEngine(),
    useCase: MockAnalyzeSongUseCase = MockAnalyzeSongUseCase()
) -> (sut: LibraryActionService, repo: MockSongStorageRepository, importService: MockLibraryImportSyncService, syncEngine: MockSyncEngine, useCase: MockAnalyzeSongUseCase) {
    let repo = MockSongStorageRepository()
    repo.fetchAllSongsResult = songs
    let sut = LibraryActionService(
        libraryImportService: importService,
        syncEngine: syncEngine,
        analyzeUseCase: useCase,
        localRepository: repo
    )
    return (sut, repo, importService, syncEngine, useCase)
}

private func makeSong(id: String, systemTags: [String] = [], userTags: [String] = []) -> VTSong {
    let song = VTSong(id: id, title: "Song \(id)", artist: "Artist")
    song.tags = systemTags.map { VibeTag.Tag(name: $0, hexColor: "#808080", isSystemTag: true) }
               + userTags.map  { VibeTag.Tag(name: $0, hexColor: "#000000", isSystemTag: false) }
    return song
}

// MARK: - refreshLibraryStats

@MainActor
@Suite("LibraryActionService.refreshLibraryStats")
struct LibraryActionServiceRefreshStatsTests {

    @Test("Sets totalSongsCount from the repository")
    func setsTotalCount() {
        let (sut, _, _, _, _) = makeSUT(songs: [makeSong(id: "s1"), makeSong(id: "s2")])
        #expect(sut.totalSongsCount == 2)
    }

    @Test("Sets unanalyzedCount to songs without system tags")
    func setsUnanalyzedCount() {
        let songs = [
            makeSong(id: "s1", systemTags: ["pop"]),
            makeSong(id: "s2"),
            makeSong(id: "s3", userTags: ["fav"])
        ]
        let (sut, _, _, _, _) = makeSUT(songs: songs)
        #expect(sut.unanalyzedCount == 2)
    }

    @Test("Sets both counts to 0 when repository is empty")
    func setsZeroWhenEmpty() {
        let (sut, _, _, _, _) = makeSUT(songs: [])
        #expect(sut.totalSongsCount == 0)
        #expect(sut.unanalyzedCount == 0)
    }
}

// MARK: - syncLibrary

@MainActor
@Suite("LibraryActionService.syncLibrary")
struct LibraryActionServiceSyncLibraryTests {

    @Test("isSyncing is false after successful sync")
    func isSyncingFalseAfterSuccess() async {
        let (sut, _, _, _, _) = makeSUT()
        await sut.syncLibrary()
        #expect(sut.isSyncing == false)
    }

    @Test("isSyncing is false even when import service throws")
    func isSyncingFalseAfterFailure() async {
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.unknown
        let (sut, _, _, _, _) = makeSUT(importService: importService)
        await sut.syncLibrary()
        #expect(sut.isSyncing == false)
    }

    @Test("Calls syncLibrary on the import service")
    func callsImportService() async {
        let importService = MockLibraryImportSyncService()
        let (sut, _, service, _, _) = makeSUT(importService: importService)
        await sut.syncLibrary()
        #expect(service.syncLibraryCallCount == 1)
    }

    @Test("Sets errorMessage when import service throws")
    func setsErrorOnFailure() async {
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.serverError(statusCode: 503)
        let (sut, _, _, _, _) = makeSUT(importService: importService)
        await sut.syncLibrary()
        #expect(sut.errorMessage != nil)
    }

    @Test("Clears errorMessage at the start of a new sync")
    func clearsErrorMessageAtStart() async {
        let (sut, _, _, _, _) = makeSUT()
        sut.errorMessage = "stale error"
        await sut.syncLibrary()
        #expect(sut.errorMessage == nil)
    }

    @Test("Refreshes library stats after successful sync")
    func refreshesStatsAfterSync() async {
        let repo = MockSongStorageRepository()
        repo.fetchAllSongsResult = []
        let importService = MockLibraryImportSyncService()
        let sut = LibraryActionService(
            libraryImportService: importService,
            syncEngine: MockSyncEngine(),
            analyzeUseCase: MockAnalyzeSongUseCase(),
            localRepository: repo
        )
        repo.fetchAllSongsResult = [makeSong(id: "s1"), makeSong(id: "s2")]
        await sut.syncLibrary()
        #expect(sut.totalSongsCount == 2)
    }
}

// MARK: - performFullSync

@MainActor
@Suite("LibraryActionService.performFullSync")
struct LibraryActionServicePerformFullSyncTests {

    @Test("isSyncing is false after successful full sync")
    func isSyncingFalseAfterSuccess() async {
        let (sut, _, _, _, _) = makeSUT()
        await sut.performFullSync()
        #expect(sut.isSyncing == false)
    }

    @Test("isSyncing is false when import service throws")
    func isSyncingFalseAfterImportFailure() async {
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.unknown
        let (sut, _, _, _, _) = makeSUT(importService: importService)
        await sut.performFullSync()
        #expect(sut.isSyncing == false)
    }

    @Test("isSyncing is false when pullRemoteData throws")
    func isSyncingFalseAfterPullFailure() async {
        let syncEngine = MockSyncEngine()
        syncEngine.pullRemoteDataShouldThrow = AppError.serverError(statusCode: 500)
        let (sut, _, _, _, _) = makeSUT(syncEngine: syncEngine)
        await sut.performFullSync()
        #expect(sut.isSyncing == false)
    }

    @Test("Calls syncLibrary on the import service")
    func callsImportService() async {
        let importService = MockLibraryImportSyncService()
        let (sut, _, service, _, _) = makeSUT(importService: importService)
        await sut.performFullSync()
        #expect(service.syncLibraryCallCount == 1)
    }

    @Test("Calls pullRemoteData on the sync engine")
    func callsPullRemoteData() async {
        let syncEngine = MockSyncEngine()
        let (sut, _, _, engine, _) = makeSUT(syncEngine: syncEngine)
        await sut.performFullSync()
        #expect(engine.pullRemoteDataCallCount == 1)
    }

    @Test("Does not call pullRemoteData when import service fails")
    func doesNotPullWhenImportFails() async {
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.unknown
        let syncEngine = MockSyncEngine()
        let (sut, _, _, engine, _) = makeSUT(importService: importService, syncEngine: syncEngine)
        await sut.performFullSync()
        #expect(engine.pullRemoteDataCallCount == 0)
    }

    @Test("Sets errorMessage when import service throws")
    func setsErrorOnImportFailure() async {
        let importService = MockLibraryImportSyncService()
        importService.syncLibraryShouldThrow = AppError.unknown
        let (sut, _, _, _, _) = makeSUT(importService: importService)
        await sut.performFullSync()
        #expect(sut.errorMessage != nil)
    }

    @Test("Sets errorMessage when pullRemoteData throws")
    func setsErrorOnPullFailure() async {
        let syncEngine = MockSyncEngine()
        syncEngine.pullRemoteDataShouldThrow = AppError.serverError(statusCode: 500)
        let (sut, _, _, _, _) = makeSUT(syncEngine: syncEngine)
        await sut.performFullSync()
        #expect(sut.errorMessage != nil)
    }

    @Test("Clears errorMessage at the start")
    func clearsErrorMessageAtStart() async {
        let (sut, _, _, _, _) = makeSUT()
        sut.errorMessage = "stale error"
        await sut.performFullSync()
        #expect(sut.errorMessage == nil)
    }
}

// MARK: - analyzeLibrary

@MainActor
@Suite("LibraryActionService.analyzeLibrary")
struct LibraryActionServiceAnalyzeLibraryTests {

    @Test("isAnalyzing is false after successful analysis")
    func isAnalyzingFalseAfterSuccess() async {
        let (sut, _, _, _, _) = makeSUT(songs: [makeSong(id: "s1")])
        await sut.analyzeLibrary()
        #expect(sut.isAnalyzing == false)
    }

    @Test("isAnalyzing is false even when analysis throws")
    func isAnalyzingFalseAfterError() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeBatchShouldThrow = AppError.serverError(statusCode: 500)
        let (sut, _, _, _, _) = makeSUT(songs: [makeSong(id: "s1")], useCase: useCase)
        await sut.analyzeLibrary()
        #expect(sut.isAnalyzing == false)
    }

    @Test("Short-circuits with 'already analyzed' status when all songs have system tags")
    func shortCircuitsWhenAllAnalyzed() async {
        let songs = [makeSong(id: "s1", systemTags: ["pop"]), makeSong(id: "s2", systemTags: ["rock"])]
        let useCase = MockAnalyzeSongUseCase()
        let (sut, _, _, _, uc) = makeSUT(songs: songs, useCase: useCase)
        await sut.analyzeLibrary()
        #expect(uc.executeCallCount == 0)
        #expect(sut.analysisStatus == "La biblioteca ya está analizada")
        #expect(sut.isAnalyzing == false)
    }

    @Test("Short-circuits when library is empty")
    func shortCircuitsWhenEmpty() async {
        let useCase = MockAnalyzeSongUseCase()
        let (sut, _, _, _, uc) = makeSUT(songs: [], useCase: useCase)
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
        let (sut, _, _, _, _) = makeSUT(songs: songs)
        await sut.analyzeLibrary()
        #expect(sut.totalToAnalyzeCount == 2)
    }

    @Test("Progress callback updates currentAnalyzedCount")
    func progressCallbackUpdatesCount() async {
        let songs = (1...3).map { makeSong(id: "s\($0)") }
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeBatchProgressSimulation = [(1, 3), (2, 3), (3, 3)]
        let (sut, _, _, _, _) = makeSUT(songs: songs, useCase: useCase)
        await sut.analyzeLibrary()
        #expect(sut.currentAnalyzedCount == 3)
    }

    @Test("analysisProgress is computed from currentAnalyzedCount and totalToAnalyzeCount")
    func progressIsComputedCorrectly() {
        let (sut, _, _, _, _) = makeSUT()
        sut.currentAnalyzedCount = 3
        sut.totalToAnalyzeCount = 10
        #expect(sut.analysisProgress == 0.3)
    }

    @Test("Sets completion status after successful analysis")
    func setsCompletionStatus() async {
        let songs = [makeSong(id: "s1")]
        let (sut, _, _, _, _) = makeSUT(songs: songs)
        await sut.analyzeLibrary()
        #expect(sut.analysisStatus == "Análisis completo!")
    }

    @Test("Sets errorMessage when executeBatch throws")
    func setsErrorMessageOnFailure() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeBatchShouldThrow = AppError.serverError(statusCode: 500)
        let (sut, _, _, _, _) = makeSUT(songs: [makeSong(id: "s1")], useCase: useCase)
        await sut.analyzeLibrary()
        #expect(sut.errorMessage != nil)
    }

    @Test("Refreshes library stats after successful analysis")
    func refreshesStatsAfterAnalysis() async {
        let repo = MockSongStorageRepository()
        let song = makeSong(id: "s1")
        repo.fetchAllSongsResult = [song]
        let sut = LibraryActionService(
            libraryImportService: MockLibraryImportSyncService(),
            syncEngine: MockSyncEngine(),
            analyzeUseCase: MockAnalyzeSongUseCase(),
            localRepository: repo
        )
        song.tags = [VibeTag.Tag(name: "pop", hexColor: "#808080", isSystemTag: true)]
        await sut.analyzeLibrary()
        #expect(sut.unanalyzedCount == 0)
    }
}

// MARK: - cancelAnalysis

@MainActor
@Suite("LibraryActionService.cancelAnalysis")
struct LibraryActionServiceCancelAnalysisTests {

    @Test("Sets isAnalyzing to false after cancellation")
    func setsIsAnalyzingFalseAfterCancel() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeBatchSuspendsIndefinitely = true
        let songs = [makeSong(id: "s1")]
        let (sut, _, _, _, _) = makeSUT(songs: songs, useCase: useCase)

        async let _ = sut.analyzeLibrary()
        // Give the task a moment to start
        try? await Task.sleep(for: .milliseconds(50))

        sut.cancelAnalysis()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(sut.isAnalyzing == false)
    }

    @Test("Sets analysisStatus to cancelled message")
    func setsAnalysisStatusCancelled() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeBatchSuspendsIndefinitely = true
        let songs = [makeSong(id: "s1")]
        let (sut, _, _, _, _) = makeSUT(songs: songs, useCase: useCase)

        async let _ = sut.analyzeLibrary()
        try? await Task.sleep(for: .milliseconds(50))

        sut.cancelAnalysis()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(sut.analysisStatus == "Análisis cancelado")
    }

    @Test("Does nothing when no analysis is running")
    func doesNothingWhenNotAnalyzing() {
        let (sut, _, _, _, _) = makeSUT()
        sut.cancelAnalysis() // Must not crash
        #expect(sut.isAnalyzing == false)
    }
}

// MARK: - pullRemoteData

@MainActor
@Suite("LibraryActionService.pullRemoteData")
struct LibraryActionServicePullRemoteDataTests {

    @Test("Delegates to the sync engine")
    func delegatesToSyncEngine() async throws {
        let syncEngine = MockSyncEngine()
        let (sut, _, _, engine, _) = makeSUT(syncEngine: syncEngine)
        try await sut.pullRemoteData()
        #expect(engine.pullRemoteDataCallCount == 1)
    }

    @Test("Propagates errors from the sync engine")
    func propagatesErrors() async {
        let syncEngine = MockSyncEngine()
        syncEngine.pullRemoteDataShouldThrow = AppError.serverError(statusCode: 500)
        let (sut, _, _, _, _) = makeSUT(syncEngine: syncEngine)
        await #expect(throws: AppError.self) {
            try await sut.pullRemoteData()
        }
    }
}

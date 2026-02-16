import Foundation
@testable import VibeTag

@MainActor
final class MockLibraryActionService: LibraryActionServiceProtocol {

    // MARK: - Observable State

    var isSyncing: Bool = false
    var isAnalyzing: Bool = false
    var currentAnalyzedCount: Int = 0
    var totalToAnalyzeCount: Int = 0
    var analysisProgress: Double = 0
    var analysisStatus: String = ""
    var errorMessage: String?
    var totalSongsCount: Int = 0
    var unanalyzedCount: Int = 0

    // MARK: - Call Tracking

    var syncLibraryCallCount = 0
    var performFullSyncCallCount = 0
    var analyzeLibraryCallCount = 0
    var cancelAnalysisCallCount = 0
    var pullRemoteDataCallCount = 0
    var refreshLibraryStatsCallCount = 0

    // MARK: - Configurable Behaviour

    var pullRemoteDataShouldThrow: Error?

    // MARK: - Protocol Conformance

    func syncLibrary() async {
        syncLibraryCallCount += 1
    }

    func performFullSync() async {
        performFullSyncCallCount += 1
    }

    func analyzeLibrary() async {
        analyzeLibraryCallCount += 1
    }

    func cancelAnalysis() {
        cancelAnalysisCallCount += 1
    }

    func pullRemoteData() async throws {
        pullRemoteDataCallCount += 1
        if let error = pullRemoteDataShouldThrow { throw error }
    }

    func refreshLibraryStats() {
        refreshLibraryStatsCallCount += 1
    }
}

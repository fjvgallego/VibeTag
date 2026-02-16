import Foundation

@MainActor
protocol LibraryActionServiceProtocol: AnyObject {
    // MARK: - State
    var isSyncing: Bool { get }
    var isAnalyzing: Bool { get }
    var currentAnalyzedCount: Int { get }
    var totalToAnalyzeCount: Int { get }
    var analysisProgress: Double { get }
    var analysisStatus: String { get }
    var errorMessage: String? { get set }
    var totalSongsCount: Int { get }
    var unanalyzedCount: Int { get }

    // MARK: - Actions
    func syncLibrary() async
    func performFullSync() async
    func analyzeLibrary() async
    func cancelAnalysis()
    func pullRemoteData() async throws
    func refreshLibraryStats()
}

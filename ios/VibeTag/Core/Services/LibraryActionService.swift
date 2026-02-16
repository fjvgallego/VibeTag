import Foundation
import Observation

@Observable
@MainActor
class LibraryActionService: LibraryActionServiceProtocol {

    // MARK: - Observable State

    var isSyncing: Bool = false
    var isAnalyzing: Bool = false
    var currentAnalyzedCount: Int = 0
    var totalToAnalyzeCount: Int = 0
    var analysisStatus: String = ""
    var errorMessage: String?
    var totalSongsCount: Int = 0
    var unanalyzedCount: Int = 0

    var analysisProgress: Double {
        guard totalToAnalyzeCount > 0 else { return 0 }
        return Double(currentAnalyzedCount) / Double(totalToAnalyzeCount)
    }

    // MARK: - Dependencies

    private let libraryImportService: LibraryImportSyncService
    private let syncEngine: any SyncEngine
    private let analyzeUseCase: AnalyzeSongUseCaseProtocol
    private let localRepository: SongStorageRepository

    private var analysisTask: Task<Void, Never>?

    init(
        libraryImportService: LibraryImportSyncService,
        syncEngine: any SyncEngine,
        analyzeUseCase: AnalyzeSongUseCaseProtocol,
        localRepository: SongStorageRepository
    ) {
        self.libraryImportService = libraryImportService
        self.syncEngine = syncEngine
        self.analyzeUseCase = analyzeUseCase
        self.localRepository = localRepository
        refreshLibraryStats()
    }

    // MARK: - Actions

    func syncLibrary() async {
        isSyncing = true
        errorMessage = nil

        do {
            try await libraryImportService.syncLibrary()
            refreshLibraryStats()
        } catch {
            errorMessage = "Error al sincronizar la biblioteca: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    func performFullSync() async {
        isSyncing = true
        errorMessage = nil

        do {
            try await libraryImportService.syncLibrary()
            try await syncEngine.pullRemoteData()
            refreshLibraryStats()
        } catch {
            errorMessage = "Error en la sincronización: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    func analyzeLibrary() async {
        isAnalyzing = true
        errorMessage = nil
        currentAnalyzedCount = 0
        analysisStatus = "Iniciando análisis..."

        analysisTask = Task {
            do {
                let songs = try localRepository.fetchAllSongs()
                let songsToAnalyze = songs.filter { !$0.tags.contains { $0.isSystemTag } }

                totalToAnalyzeCount = songsToAnalyze.count

                guard !songsToAnalyze.isEmpty else {
                    analysisStatus = "La biblioteca ya está analizada"
                    refreshLibraryStats()
                    isAnalyzing = false
                    return
                }

                try await analyzeUseCase.executeBatch(songs: songsToAnalyze) { current, total in
                    self.currentAnalyzedCount = current
                    self.analysisStatus = "Analizando \(current)/\(total)..."
                }

                analysisStatus = "Análisis completo!"
                refreshLibraryStats()
            } catch is CancellationError {
                analysisStatus = "Análisis cancelado"
                refreshLibraryStats()
            } catch {
                errorMessage = "Error en el análisis: \(error.localizedDescription)"
            }

            isAnalyzing = false
        }

        await analysisTask?.value
    }

    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
    }

    func pullRemoteData() async throws {
        try await syncEngine.pullRemoteData()
    }

    func refreshLibraryStats() {
        do {
            let songs = try localRepository.fetchAllSongs()
            totalSongsCount = songs.count
            unanalyzedCount = songs.filter { !$0.tags.contains { $0.isSystemTag } }.count
        } catch {
            print("Error refreshing library stats: \(error)")
        }
    }
}

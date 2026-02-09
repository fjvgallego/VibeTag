import Foundation
import Observation
import SwiftData
import MusicKit

@Observable
class SettingsViewModel {
    var isSyncing = false
    var isAnalyzing = false
    var analysisProgress: Double = 0
    var analysisStatus: String = ""
    var errorMessage: String? = nil
    
    var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined
    
    var isAppleMusicLinked: Bool {
        musicAuthorizationStatus == .authorized
    }
    
    private let analyzeUseCase: AnalyzeSongUseCase
    private let localRepository: SongStorageRepository
    
    init(analyzeUseCase: AnalyzeSongUseCase, localRepository: SongStorageRepository) {
        self.analyzeUseCase = analyzeUseCase
        self.localRepository = localRepository
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
    }
    
    func updateAuthorizationStatus() {
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
    }
    
    func requestMusicPermissions() {
        Task {
            let status = await MusicAuthorization.request()
            await MainActor.run {
                self.musicAuthorizationStatus = status
            }
        }
    }
    
    @MainActor
    func performFullSync(modelContext: ModelContext, syncEngine: VibeTagSyncEngine) async {
        isSyncing = true
        errorMessage = nil

        do {
            // 1. Sync local library with Apple Music
            let service = AppleMusicLibraryImportService(modelContext: modelContext)
            try await service.syncLibrary()

            // 2. Pull remote data
            try await syncEngine.pullRemoteData()
        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }

        isSyncing = false
    }
    
    @MainActor
    func analyzeLibrary() async {
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0
        analysisStatus = "Iniciando análisis..."
        
        do {
            let songs = try localRepository.fetchAllSongs()
            let songsToAnalyze = songs.filter { $0.tags.isEmpty }
            
            if songsToAnalyze.isEmpty {
                analysisStatus = "La biblioteca ya está analizada"
                isAnalyzing = false
                return
            }
            
            try await analyzeUseCase.executeBatch(songs: songsToAnalyze) { current, total in
                self.analysisProgress = Double(current) / Double(total)
                self.analysisStatus = "Analizando \(current)/\(total)..."
            }
            
            let remaining = try localRepository.fetchAllSongs().filter { $0.tags.isEmpty }.count
            if remaining > 0 {
                analysisStatus = "Análisis finalizado con \(remaining) canciones omitidas."
            } else {
                analysisStatus = "¡Análisis completo!"
            }
        } catch {
            errorMessage = "Error en el análisis: \(error.localizedDescription)"
        }
        
        isAnalyzing = false
    }
}

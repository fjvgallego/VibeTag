import Foundation
import SwiftData
import SwiftUI
import MusicKit

enum FilterScope: String, CaseIterable, Identifiable {
    case all = "Todas"
    case untagged = "Sin etiquetas"
    case system = "IA"
    case user = "Usuario"
    
    var id: String { self.rawValue }
}

enum SortOption: String, CaseIterable, Identifiable {
    case songName = "Nombre de canción"
    case artistName = "Nombre de artista"
    case albumName = "Álbum"
    case dateAdded = "Fecha añadida"
    case tagCount = "Número de etiquetas"
    
    var id: String { self.rawValue }
}

@MainActor
@Observable
class HomeViewModel {
    var searchText: String = ""
    var selectedFilter: FilterScope = .all
    var selectedSort: SortOption = .dateAdded
    var selectedOrder: SortOrder = .descending
    var isSyncing: Bool = false
    var isAnalyzing: Bool = false
    var currentAnalyzedCount: Int = 0
    var totalToAnalyzeCount: Int = 0
    var analysisStatus: String = ""
    var errorMessage: String?
    
    var totalSongsCount: Int = 0
    var unanalyzedCount: Int = 0
    
    var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined
    
    var isAppleMusicLinked: Bool {
        musicAuthorizationStatus == .authorized
    }
    
    var analysisProgress: Double {
        guard totalToAnalyzeCount > 0 else { return 0 }
        return Double(currentAnalyzedCount) / Double(totalToAnalyzeCount)
    }
    
    private let analyzeUseCase: AnalyzeSongUseCaseProtocol
    private let localRepository: SongStorageRepository
    
    init(analyzeUseCase: AnalyzeSongUseCaseProtocol, localRepository: SongStorageRepository) {
        self.analyzeUseCase = analyzeUseCase
        self.localRepository = localRepository
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
        refreshLibraryStats()
    }
    
    func refreshLibraryStats() {
        do {
            let songs = try localRepository.fetchAllSongs()
            self.totalSongsCount = songs.count
            self.unanalyzedCount = songs.filter { song in 
                !song.tags.contains { $0.isSystemTag }
            }.count
        } catch {
            print("Error refreshing library stats: \(error)")
        }
    }
    
    func updateAuthorizationStatus() {
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
        refreshLibraryStats()
    }
    
    func requestMusicPermissions() {
        Task {
            let status = await MusicAuthorization.request()
            await MainActor.run {
                self.musicAuthorizationStatus = status
                self.refreshLibraryStats()
            }
        }
    }
    
    func syncLibrary(modelContext: ModelContext) async {
        isSyncing = true
        errorMessage = nil
        
        do {
            let service = AppleMusicLibraryImportService(modelContext: modelContext)
            try await service.syncLibrary()
            refreshLibraryStats()
        } catch {
            errorMessage = "Failed to sync library: \(error.localizedDescription)"
        }
        
        isSyncing = false
    }

    func performFullSync(modelContext: ModelContext, syncEngine: VibeTagSyncEngine) async {
        isSyncing = true
        errorMessage = nil

        do {
            // 1. Sync local library with Apple Music
            let service = AppleMusicLibraryImportService(modelContext: modelContext)
            try await service.syncLibrary()

            // 2. Pull remote data
            try await syncEngine.pullRemoteData()
            refreshLibraryStats()
        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }

        isSyncing = false
    }
    
    func analyzeLibrary() async {
        isAnalyzing = true
        errorMessage = nil
        currentAnalyzedCount = 0
        analysisStatus = "Iniciando análisis..."
        
        do {
            let songs = try localRepository.fetchAllSongs()
            let songsToAnalyze = songs.filter { song in
                !song.tags.contains { $0.isSystemTag }
            }
            
            totalToAnalyzeCount = songsToAnalyze.count
            
            if songsToAnalyze.isEmpty {
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
        } catch {
            errorMessage = "Error en el análisis: \(error.localizedDescription)"
        }
        
        isAnalyzing = false
    }
}

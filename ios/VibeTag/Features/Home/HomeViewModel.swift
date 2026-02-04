import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class HomeViewModel {
    var searchText: String = ""
    var isSyncing: Bool = false
    var isAnalyzing: Bool = false
    var analysisProgress: Double = 0
    var analysisStatus: String = ""
    var errorMessage: String?
    
    private let analyzeUseCase: AnalyzeSongUseCaseProtocol
    private let localRepository: SongStorageRepository
    
    init(analyzeUseCase: AnalyzeSongUseCaseProtocol, localRepository: SongStorageRepository) {
        self.analyzeUseCase = analyzeUseCase
        self.localRepository = localRepository
    }
    
    var searchTokens: [String] {
        SearchQueryHelper.expand(text: searchText)
    }
    
    func syncLibrary(modelContext: ModelContext) async {
        isSyncing = true
        errorMessage = nil
        
        do {
            let service = AppleMusicLibraryImportService(modelContext: modelContext)
            try await service.syncLibrary()
        } catch {
            errorMessage = "Failed to sync library: \(error.localizedDescription)"
        }
        
        isSyncing = false
    }
    
    func analyzeLibrary() async {
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0
        analysisStatus = "Starting analysis..."
        
        do {
            let songs = try localRepository.fetchAllSongs()
            let songsToAnalyze = songs.filter { $0.tags.isEmpty }
            
            if songsToAnalyze.isEmpty {
                analysisStatus = "Library is already analyzed"
                isAnalyzing = false
                return
            }
            
            try await analyzeUseCase.executeBatch(songs: songsToAnalyze) { current, total in
                self.analysisProgress = Double(current) / Double(total)
                self.analysisStatus = "Analyzing \(current)/\(total)..."
            }
            
            // After batch, check if there are still songs without tags (partial failure)
            let remaining = try localRepository.fetchAllSongs().filter { $0.tags.isEmpty }.count
            if remaining > 0 {
                analysisStatus = "Analysis finished with \(remaining) songs skipped."
            } else {
                analysisStatus = "Analysis complete!"
            }
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }
        
        isAnalyzing = false
    }
}

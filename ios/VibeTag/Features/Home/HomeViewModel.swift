import Foundation
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

    // MARK: - UI-only State

    var searchText: String = ""
    var selectedFilter: FilterScope = .all
    var selectedSort: SortOption = .dateAdded
    var selectedOrder: SortOrder = .descending
    var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined

    // MARK: - Pass-throughs from LibraryActionService

    var isSyncing: Bool { libraryActionService.isSyncing }
    var isAnalyzing: Bool { libraryActionService.isAnalyzing }
    var currentAnalyzedCount: Int { libraryActionService.currentAnalyzedCount }
    var totalToAnalyzeCount: Int { libraryActionService.totalToAnalyzeCount }
    var analysisProgress: Double { libraryActionService.analysisProgress }
    var analysisStatus: String { libraryActionService.analysisStatus }
    var totalSongsCount: Int { libraryActionService.totalSongsCount }
    var unanalyzedCount: Int { libraryActionService.unanalyzedCount }
    var errorMessage: String? {
        get { libraryActionService.errorMessage }
        set { libraryActionService.errorMessage = newValue }
    }

    var isAppleMusicLinked: Bool {
        musicAuthorizationStatus == .authorized
    }

    // MARK: - Dependencies

    private let libraryActionService: LibraryActionServiceProtocol

    init(libraryActionService: LibraryActionServiceProtocol) {
        self.libraryActionService = libraryActionService
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
    }

    // MARK: - Actions

    func updateAuthorizationStatus() {
        musicAuthorizationStatus = MusicAuthorization.currentStatus
        libraryActionService.refreshLibraryStats()
    }

    func requestMusicPermissions() {
        Task {
            let status = await MusicAuthorization.request()
            await MainActor.run {
                self.musicAuthorizationStatus = status
                self.libraryActionService.refreshLibraryStats()
            }
        }
    }

    func refreshLibraryStats() {
        libraryActionService.refreshLibraryStats()
    }

    func syncLibrary() async {
        await libraryActionService.syncLibrary()
    }

    func performFullSync() async {
        await libraryActionService.performFullSync()
    }

    func analyzeLibrary() async {
        await libraryActionService.analyzeLibrary()
    }

    func cancelAnalysis() {
        libraryActionService.cancelAnalysis()
    }
}

import Foundation
import SwiftData

class AppContainer {
    let modelContext: ModelContext
    let localRepo: LocalSongStorageRepositoryImpl
    let appleMusicRepo: AppleMusicSongRepositoryImpl
    let authRepo: VibeTagAuthRepositoryImpl
    let musicLibraryRepo: AppleMusicLibraryRepositoryImpl
    let analyzeSongUseCase: AnalyzeSongUseCase
    let generatePlaylistUseCase: GeneratePlaylistUseCase
    let exportPlaylistUseCase: ExportPlaylistToAppleMusicUseCase
    let tokenStorage: TokenStorage
    let sessionManager: SessionManager
    let syncEngine: VibeTagSyncEngine
    let libraryActionService: LibraryActionService

    init(modelContext: ModelContext) {
        // Data layer
        self.modelContext = modelContext
        let localRepo = LocalSongStorageRepositoryImpl(modelContext: modelContext)
        self.localRepo = localRepo
        self.appleMusicRepo = AppleMusicSongRepositoryImpl()
        self.authRepo = VibeTagAuthRepositoryImpl()
        self.musicLibraryRepo = AppleMusicLibraryRepositoryImpl()
        let tokenStorage = KeychainTokenStorage()
        self.tokenStorage = tokenStorage

        // Use cases
        self.analyzeSongUseCase = AnalyzeSongUseCase(
            remoteRepository: self.appleMusicRepo,
            localRepository: localRepo
        )
        self.generatePlaylistUseCase = GeneratePlaylistUseCase()
        self.exportPlaylistUseCase = ExportPlaylistToAppleMusicUseCaseImpl(repository: self.musicLibraryRepo)

        // Services
        let sessionManager = SessionManager(
            tokenStorage: tokenStorage,
            authRepository: self.authRepo,
            onAccountDeleted: { Task { try? await localRepo.clearAllTags() } },
            onLogout: { Task { try? await localRepo.clearAllTags() } }
        )
        self.sessionManager = sessionManager

        let syncEngine = VibeTagSyncEngine(localRepo: localRepo, sessionManager: sessionManager)
        self.syncEngine = syncEngine

        let libraryImportService = AppleMusicLibraryImportService(modelContext: modelContext)
        self.libraryActionService = LibraryActionService(
            libraryImportService: libraryImportService,
            syncEngine: syncEngine,
            analyzeUseCase: self.analyzeSongUseCase,
            localRepository: localRepo
        )
    }
}

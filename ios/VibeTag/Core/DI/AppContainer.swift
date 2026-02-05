import Foundation
import SwiftData

class AppContainer {
    let localRepo: LocalSongStorageRepositoryImpl
    let appleMusicRepo: AppleMusicSongRepositoryImpl
    let authRepo: VibeTagAuthRepositoryImpl
    let analyzeSongUseCase: AnalyzeSongUseCase
    let generatePlaylistUseCase: GeneratePlaylistUseCase
    let tokenStorage: TokenStorage
    
    init(modelContext: ModelContext) {
        self.localRepo = LocalSongStorageRepositoryImpl(modelContext: modelContext)
        self.appleMusicRepo = AppleMusicSongRepositoryImpl()
        self.authRepo = VibeTagAuthRepositoryImpl()
        self.tokenStorage = KeychainTokenStorage()
        
        self.analyzeSongUseCase = AnalyzeSongUseCase(
            remoteRepository: self.appleMusicRepo,
            localRepository: self.localRepo
        )
        self.generatePlaylistUseCase = GeneratePlaylistUseCase()
    }
}

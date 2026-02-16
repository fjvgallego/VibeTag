import Foundation

protocol ExportPlaylistToAppleMusicUseCase {
    func execute(name: String, description: String, appleMusicIds: [String]) async throws
}

class ExportPlaylistToAppleMusicUseCaseImpl: ExportPlaylistToAppleMusicUseCase {
    private let repository: MusicLibraryRepository
    
    init(repository: MusicLibraryRepository) {
        self.repository = repository
    }
    
    func execute(name: String, description: String, appleMusicIds: [String]) async throws {
        try await repository.createPlaylist(name: name, description: description, appleMusicIds: appleMusicIds)
    }
}

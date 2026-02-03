import Foundation

protocol AnalyzeSongUseCaseProtocol {
    func execute(song: VTSong) async throws -> [String]
}

class AnalyzeSongUseCase: AnalyzeSongUseCaseProtocol {
    private let remoteRepository: SongRepository
    private let localRepository: SongStorageRepository
    
    init(remoteRepository: SongRepository, localRepository: SongStorageRepository) {
        self.remoteRepository = remoteRepository
        self.localRepository = localRepository
    }
    
    func execute(song: VTSong) async throws -> [String] {
        // 1. Check Local: If the song already has tags, return them immediately.
        // We assume the VTSong object passed in is from the local database.
        if !song.tags.isEmpty {
            return song.tags.map { $0.name }
        }
        
        // 2. If No Local Data: Call remoteRepository.fetchAnalysis(for: song).
        let result = try await remoteRepository.fetchAnalysis(for: song)
        
        // 3. Save: Call localRepository.saveTags(for: song.id, tags: result).
        try await localRepository.saveTags(for: song.id, tags: result)
        
        return result
    }
}

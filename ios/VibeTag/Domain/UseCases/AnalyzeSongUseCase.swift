import Foundation

protocol AnalyzeSongUseCaseProtocol {
    func execute(song: VTSong) async throws -> [AnalyzedTag]
    func executeBatch(songs: [VTSong], onProgress: @escaping (Int, Int) -> Void) async throws
}

class AnalyzeSongUseCase: AnalyzeSongUseCaseProtocol {
    private let remoteRepository: SongRepository
    private let localRepository: SongStorageRepository
    
    init(remoteRepository: SongRepository, localRepository: SongStorageRepository) {
        self.remoteRepository = remoteRepository
        self.localRepository = localRepository
    }
    
    func execute(song: VTSong) async throws -> [AnalyzedTag] {
        // 1. Check Local: If the song already has system tags, return them (mapped to domain model).
        let systemTags = song.tags.filter { $0.isSystemTag }
        if !systemTags.isEmpty {
            return systemTags.map { AnalyzedTag(name: $0.name, description: $0.tagDescription) }
        }
        
        // 2. If No System Data: Call remoteRepository.fetchAnalysis(for: song).
        let result = try await remoteRepository.fetchAnalysis(for: song)
        
        // 3. Save: Call localRepository.saveTags(for: song.id, tags: result).
        try await localRepository.saveTags(for: song.id, tags: result)
        
        return result
    }
    
    func executeBatch(songs: [VTSong], onProgress: @escaping (Int, Int) -> Void) async throws {
        // Filter songs that don't have system (AI) tags
        let songsToAnalyze = songs.filter { song in
            !song.tags.contains { $0.isSystemTag }
        }
        let totalCount = songsToAnalyze.count
        var currentCount = 0
        
        guard totalCount > 0 else {
            onProgress(0, 0)
            return
        }
        
        // Chunking: Split the array into chunks of 5
        let chunkSize = 50
        let chunks = stride(from: 0, to: totalCount, by: chunkSize).map {
            Array(songsToAnalyze[$0..<min($0 + chunkSize, totalCount)])
        }
        
        var firstError: Error?
        var successCount = 0
        
        for chunk in chunks {
            do {
                let results = try await remoteRepository.fetchBatchAnalysis(for: chunk)
                
                // Save results to Local DB
                for result in results {
                    try await localRepository.saveTags(for: result.songId, tags: result.tags)
                }
                successCount += 1
            } catch {
                print("Error analyzing chunk: \(error.localizedDescription)")
                if firstError == nil { firstError = error }
                
                // If it's a critical error (like unauthorized), throw immediately
                if case AppError.unauthorized = error {
                    throw error
                }
                // Continue to next chunk for other errors
            }
            
            currentCount += chunk.count
            onProgress(currentCount, totalCount)
        }
        
        // If everything failed, throw the first error we encountered
        if successCount == 0, let error = firstError {
            throw error
        }
    }
}

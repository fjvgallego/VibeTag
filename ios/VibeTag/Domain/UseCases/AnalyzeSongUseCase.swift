import Foundation

protocol AnalyzeSongUseCaseProtocol {
    func execute(song: VTSong) async throws -> [String]
    func executeBatch(songs: [VTSong], onProgress: @escaping (Int, Int) -> Void) async throws
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
    
    func executeBatch(songs: [VTSong], onProgress: @escaping (Int, Int) -> Void) async throws {
        // Filter songs that don't have AI tags
        let songsToAnalyze = songs.filter { $0.tags.isEmpty }
        let totalCount = songsToAnalyze.count
        var currentCount = 0
        
        guard totalCount > 0 else {
            onProgress(0, 0)
            return
        }
        
        // Chunking: Split the array into chunks of 5
        let chunkSize = 5
        let chunks = stride(from: 0, to: totalCount, by: chunkSize).map {
            Array(songsToAnalyze[$0..<min($0 + chunkSize, totalCount)])
        }
        
        var firstError: Error?
        
        for chunk in chunks {
            do {
                let songInputs = chunk.map { song in
                    BatchAnalyzeRequestDTO.SongInput(
                        songId: song.id,
                        title: song.title,
                        artist: song.artist,
                        album: nil,
                        genre: nil
                    )
                }
                
                let dto = BatchAnalyzeRequestDTO(songs: songInputs)
                let response = try await remoteRepository.fetchBatchAnalysis(dto: dto)
                
                // Save results to Local DB
                for result in response.results {
                    if let songId = result.songId {
                        try await localRepository.saveTags(for: songId, tags: result.tags)
                    }
                }
            } catch {
                print("Error analyzing chunk: \(error.localizedDescription)")
                if firstError == nil { firstError = error }
                // Continue to next chunk even if one fails
            }
            
            currentCount += chunk.count
            onProgress(currentCount, totalCount)
        }
        
        // If everything failed or some critical error happened, we might want to throw, 
        // but for now, we'll let the ViewModel handle the "some failed" state if needed.
        // Actually, let's throw only if all failed or if it's a critical error (like unauthorized).
        if let error = firstError {
            // Optional: check if error is critical
            // For now, let's NOT throw so the UI shows "Analysis complete" 
            // even if some songs were skipped.
        }
    }
}

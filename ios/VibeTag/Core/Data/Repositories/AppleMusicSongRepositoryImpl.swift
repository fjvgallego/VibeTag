import Foundation
import MusicKit
import Observation

@Observable
@MainActor
class AppleMusicSongRepositoryImpl: SongRepository {
    
    func fetchAnalysis(for song: VTSong) async throws -> [AnalyzedTag] {
        let endpoint = SongEndpoint.analyze(id: song.id, artist: song.artist, title: song.title)
        do {
            let response: AnalyzeResponseDTO = try await APIClient.shared.request(endpoint)
            return response.tags.map { AnalyzedTag(name: $0.name, description: $0.description) }
        } catch let apiError as APIError {
            throw apiError.toAppError
        } catch {
            throw AppError.unknown
        }
    }
    
    func fetchBatchAnalysis(for songs: [VTSong]) async throws -> [SongAnalysisResult] {
        let songInputs = songs.map { song in
            BatchAnalyzeRequestDTO.SongInput(
                songId: song.id,
                title: song.title,
                artist: song.artist,
                album: song.album,
                genre: song.genre
            )
        }
        
        let dto = BatchAnalyzeRequestDTO(songs: songInputs)
        let endpoint = SongEndpoint.analyzeBatch(dto: dto)
        
        do {
            let response: BatchAnalyzeResponseDTO = try await APIClient.shared.request(endpoint)
            
            return response.results.compactMap { result in
                guard let songId = result.songId else { return nil }
                return SongAnalysisResult(
                    songId: songId,
                    tags: result.tags.map { AnalyzedTag(name: $0.name, description: $0.description) }
                )
            }
        } catch let apiError as APIError {
            throw apiError.toAppError
        } catch {
            throw AppError.unknown
        }
    }
    
    func fetchSongs(limit: Int) async throws -> [VTSong] {
        let maxSafetyLimit = 1000
        let effectiveLimit = limit <= 0 ? maxSafetyLimit : limit
        
        var request = MusicLibraryRequest<Song>()
        request.limit = min(effectiveLimit, 100)
        
        let response = try await request.response()
        var currentBatch = response.items
        var allSongs = currentBatch.map { mapToVTSong($0) }
        
        while let nextBatch = try await currentBatch.nextBatch() {
            let nextSongs = nextBatch.map { mapToVTSong($0) }
            allSongs.append(contentsOf: nextSongs)
            currentBatch = nextBatch
            
            if allSongs.count >= effectiveLimit {
                break
            }
        }
        
        if allSongs.count > effectiveLimit {
            return Array(allSongs.prefix(effectiveLimit))
        }
        
        return allSongs
    }

    func searchSongs(query: String) async throws -> [VTSong] {
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = 25
        let response = try await request.response()
        return response.songs.map { mapToVTSong($0) }
    }
    
    private func mapToVTSong(_ song: Song) -> VTSong {
        return VTSong(
            id: song.id.rawValue,
            title: song.title,
            artist: song.artistName,
            album: song.albumTitle,
            genre: song.genreNames.first,
            artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString,
            dateAdded: song.libraryAddedDate ?? Date()
        )
    }
}

import Foundation
import MusicKit
import Observation

@Observable
@MainActor
class AppleMusicSongRepositoryImpl: SongRepository {
    
    func fetchAnalysis(for song: VTSong) async throws -> [String] {
        let endpoint = SongEndpoint.analyze(id: song.id, artist: song.artist, title: song.title)
        let response: AnalyzeResponseDTO = try await APIClient.shared.request(endpoint)
        return response.toDomain()
    }
    
    func fetchBatchAnalysis(dto: BatchAnalyzeRequestDTO) async throws -> BatchAnalyzeResponseDTO {
        let endpoint = SongEndpoint.analyzeBatch(dto: dto)
        return try await APIClient.shared.request(endpoint)
    }
    
    func fetchSongs(limit: Int) async throws -> [VTSong] {
        var request = MusicLibraryRequest<Song>()
        request.limit = limit
        let items = try await request.response().items
        return items.map { mapToVTSong($0) }
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
            artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString,
            dateAdded: song.libraryAddedDate ?? Date()
        )
    }
}

import Foundation
import MusicKit

class AppleMusicRepository: MusicRepository {
    
    func requestAuthorization() async -> MusicAuthorization.Status {
        return await MusicAuthorization.request()
    }
    
    func getAuthorizationStatus() -> MusicAuthorization.Status {
        return MusicAuthorization.currentStatus
    }
    
    func canPlayCatalogContent() async throws -> Bool {
        return try await MusicSubscription.current.canPlayCatalogContent
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
            dateAdded: Date()
        )
    }
}

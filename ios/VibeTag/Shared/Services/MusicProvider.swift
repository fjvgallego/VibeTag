import Foundation
import MusicKit

protocol MusicLibraryProvider {
    func requestAuthorization() async -> MusicAuthorization.Status
    func getAuthorizationStatus() -> MusicAuthorization.Status
    func canPlayCatalogContent() async throws -> Bool
    func fetchSongs(limit: Int) async throws -> MusicItemCollection<Song>
}

class MusicKitProvider: MusicLibraryProvider {
    func requestAuthorization() async -> MusicAuthorization.Status {
        return await MusicAuthorization.request()
    }
    
    func getAuthorizationStatus() -> MusicAuthorization.Status {
        return MusicAuthorization.currentStatus
    }
    
    func canPlayCatalogContent() async throws -> Bool {
        return try await MusicSubscription.current.canPlayCatalogContent
    }
    
    func fetchSongs(limit: Int) async throws -> MusicItemCollection<Song> {
        var request = MusicLibraryRequest<Song>()
        request.limit = limit
        return try await request.response().items
    }
}

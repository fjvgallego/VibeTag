import Foundation
import MusicKit

class AppleMusicLibraryRepositoryImpl: MusicLibraryRepository {
    func createPlaylist(name: String, description: String, appleMusicIds: [String]) async throws {
        
        // 1. Resolve MusicKit Songs from IDs
        let musicItemIDs = appleMusicIds.map { MusicItemID($0) }
        let request = MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: musicItemIDs)
        let response = try await request.response()
        
        // 2. Create the playlist
//        let playlist = try await MusicLibrary.shared.createPlaylist(name: name, description: description)
        
        // 3. Add songs to the playlist
        try await MusicLibrary.shared.createPlaylist(name: "Test", items: response.items)
    }
}

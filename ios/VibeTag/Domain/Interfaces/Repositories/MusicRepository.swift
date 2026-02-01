import Foundation
import MusicKit

@MainActor
protocol MusicRepository {
    func searchSongs(query: String) async throws -> [VTSong]
    func requestAuthorization() async -> MusicAuthorization.Status
    func getAuthorizationStatus() -> MusicAuthorization.Status
    func canPlayCatalogContent() async throws -> Bool
    func fetchSongs(limit: Int) async throws -> [VTSong]
}
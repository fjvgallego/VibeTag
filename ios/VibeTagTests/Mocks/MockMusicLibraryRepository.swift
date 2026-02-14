import Foundation
@testable import VibeTag

final class MockMusicLibraryRepository: MusicLibraryRepository {
    var createPlaylistCallCount = 0
    var createPlaylistLastName: String?
    var createPlaylistLastDescription: String?
    var createPlaylistLastAppleMusicIds: [String]?
    var createPlaylistShouldThrow: Error?

    func createPlaylist(name: String, description: String, appleMusicIds: [String]) async throws {
        createPlaylistCallCount += 1
        createPlaylistLastName = name
        createPlaylistLastDescription = description
        createPlaylistLastAppleMusicIds = appleMusicIds
        if let error = createPlaylistShouldThrow { throw error }
    }
}

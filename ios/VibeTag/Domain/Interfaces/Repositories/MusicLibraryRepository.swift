import Foundation

protocol MusicLibraryRepository {
    func createPlaylist(name: String, description: String, appleMusicIds: [String]) async throws
}

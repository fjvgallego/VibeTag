import Foundation
@testable import VibeTag

@MainActor
final class MockSongStorageRepository: SongStorageRepository {

    // MARK: - saveTags

    var saveTagsCallCount = 0
    var saveTagsReceivedCalls: [(songId: String, tags: [AnalyzedTag], syncStatus: SyncStatus)] = []
    var saveTagsShouldThrow: Error?

    func saveTags(for songId: String, tags: [AnalyzedTag], syncStatus: SyncStatus) async throws {
        saveTagsCallCount += 1
        saveTagsReceivedCalls.append((songId, tags, syncStatus))
        if let error = saveTagsShouldThrow { throw error }
    }

    // MARK: - Unused in AnalyzeSongUseCase tests

    func fetchAllSongs() throws -> [VTSong] { [] }
    func fetchSong(id: String) throws -> VTSong? { nil }
    func fetchTag(name: String) throws -> Tag? { nil }
    func songExists(id: String) throws -> Bool { false }
    func saveSong(_ song: VTSong) {}
    func deleteSong(_ song: VTSong) {}
    func markAsSynced(songId: String) async throws {}
    func fetchPendingUploads() async throws -> [VTSong] { [] }
    func hydrateRemoteTags(_ remoteItems: [RemoteSongSyncInfo]) async throws {}
    func clearAllTags() async throws {}
    func saveChanges() throws {}
}

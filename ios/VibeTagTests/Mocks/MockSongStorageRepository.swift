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

    // MARK: - fetchPendingUploads

    var fetchPendingUploadsCallCount = 0
    var pendingUploadsResult: [VTSong] = []

    func fetchPendingUploads() async throws -> [VTSong] {
        fetchPendingUploadsCallCount += 1
        return pendingUploadsResult
    }

    // MARK: - fetchSong

    var fetchSongResult: ((String) -> VTSong?)? = nil

    func fetchSong(id: String) throws -> VTSong? {
        fetchSongResult?(id)
    }

    // MARK: - markAsSynced

    var markAsSyncedCallCount = 0
    var markAsSyncedLastSongId: String?

    func markAsSynced(songId: String) async throws {
        markAsSyncedCallCount += 1
        markAsSyncedLastSongId = songId
    }

    // MARK: - hydrateRemoteTags

    var hydrateRemoteTagsCallCount = 0
    var hydrateRemoteTagsReceivedItems: [[RemoteSongSyncInfo]] = []

    func hydrateRemoteTags(_ remoteItems: [RemoteSongSyncInfo]) async throws {
        hydrateRemoteTagsCallCount += 1
        hydrateRemoteTagsReceivedItems.append(remoteItems)
    }

    // MARK: - fetchAllSongs

    var fetchAllSongsResult: [VTSong] = []
    var fetchAllSongsShouldThrow: Error?

    func fetchAllSongs() throws -> [VTSong] {
        if let error = fetchAllSongsShouldThrow { throw error }
        return fetchAllSongsResult
    }

    // MARK: - Remaining stubs
    func fetchTag(name: String) throws -> VibeTag.Tag? { nil }
    func songExists(id: String) throws -> Bool { false }
    func saveSong(_ song: VTSong) {}
    func deleteSong(_ song: VTSong) {}
    func clearAllTags() async throws {}
    func saveChanges() throws {}
}

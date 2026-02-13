import Foundation

@MainActor
protocol SongStorageRepository {
    func fetchAllSongs() throws -> [VTSong]
    func fetchSong(id: String) throws -> VTSong?
    func fetchTag(name: String) throws -> Tag?
    func songExists(id: String) throws -> Bool
    func saveSong(_ song: VTSong)
    func deleteSong(_ song: VTSong)
    func saveTags(for songId: String, tags: [AnalyzedTag], syncStatus: SyncStatus) async throws
    func markAsSynced(songId: String) async throws
    func fetchPendingUploads() async throws -> [VTSong]
    func hydrateRemoteTags(_ remoteItems: [RemoteSongSyncInfo]) async throws
    func clearAllTags() async throws
    func saveChanges() throws
}

extension SongStorageRepository {
    func saveTags(for songId: String, tags: [AnalyzedTag], syncStatus: SyncStatus = .pendingUpload) async throws {
        try await saveTags(for: songId, tags: tags, syncStatus: syncStatus)
    }
}

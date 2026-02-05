import Foundation

@MainActor
protocol SongStorageRepository {
    func fetchAllSongs() throws -> [VTSong]
    func fetchSong(id: String) throws -> VTSong?
    func songExists(id: String) throws -> Bool
    func saveSong(_ song: VTSong)
    func deleteSong(_ song: VTSong)
    func saveTags(for songId: String, tags: [AnalyzedTag]) async throws
    func markAsSynced(songId: String) async throws
    func fetchPendingUploads() async throws -> [VTSong]
    func hydrateRemoteTags(_ remoteItems: [RemoteSongSyncInfo]) async throws
    func saveChanges() throws
}

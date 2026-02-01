import Foundation

@MainActor
protocol SongStorageRepository {
    func fetchAllSongs() throws -> [VTSong]
    func songExists(id: String) throws -> Bool
    func saveSong(_ song: VTSong)
    func deleteSong(_ song: VTSong)
    func saveChanges() throws
}

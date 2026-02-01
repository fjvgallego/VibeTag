import Foundation
import SwiftData

@MainActor
class LocalSongStorageRepository: SongStorageRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAllSongs() throws -> [VTSong] {
        let descriptor = FetchDescriptor<VTSong>()
        return try modelContext.fetch(descriptor)
    }
    
    func songExists(id: String) throws -> Bool {
        let descriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == id })
        let count = try modelContext.fetchCount(descriptor)
        return count > 0
    }
    
    func saveSong(_ song: VTSong) {
        modelContext.insert(song)
    }
    
    func deleteSong(_ song: VTSong) {
        modelContext.delete(song)
    }
    
    func saveChanges() throws {
        try modelContext.save()
    }
}

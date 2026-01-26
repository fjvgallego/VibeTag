import Foundation
import SwiftData

protocol SongPersistenceService {
    func songExists(id: String) throws -> Bool
    func saveSong(_ song: VTSong)
    func saveChanges() throws
}

class SwiftDataSongStorage: SongPersistenceService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func songExists(id: String) throws -> Bool {
        let descriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == id })
        let count = try modelContext.fetchCount(descriptor)
        return count > 0
    }
    
    func saveSong(_ song: VTSong) {
        modelContext.insert(song)
    }
    
    func saveChanges() throws {
        try modelContext.save()
    }
}

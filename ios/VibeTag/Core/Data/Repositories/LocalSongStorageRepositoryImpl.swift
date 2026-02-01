import Foundation
import SwiftData

@MainActor
class LocalSongStorageRepositoryImpl: SongStorageRepository {
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

    func saveTags(for songId: String, tags: [String]) async throws {
        let songDescriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == songId })
        guard let song = try modelContext.fetch(songDescriptor).first else {
            return
        }

        var updatedTags: [Tag] = []
        
        for tagName in tags {
            let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == tagName })
            if let existingTag = try modelContext.fetch(tagDescriptor).first {
                updatedTags.append(existingTag)
            } else {
                let newTag = Tag(name: tagName, hexColor: "#808080", isSystemTag: true)
                modelContext.insert(newTag)
                updatedTags.append(newTag)
            }
        }
        
        song.tags = updatedTags
        try modelContext.save()
    }
    
    func saveChanges() throws {
        try modelContext.save()
    }
}

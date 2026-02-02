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
        let songId = id
        let descriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == songId })
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
        let id = songId
        let songDescriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == id })
        guard let song = try modelContext.fetch(songDescriptor).first else {
            return
        }

        var updatedTags: [Tag] = []
        
        for tagName in tags {
            let name = tagName
            let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == name })
            if let existingTag = try modelContext.fetch(tagDescriptor).first {
                updatedTags.append(existingTag)
            } else {
                let newTag = Tag(name: name, hexColor: "#808080", isSystemTag: false)
                modelContext.insert(newTag)
                updatedTags.append(newTag)
            }
        }
        
        song.tags = updatedTags
        song.syncStatus = .pendingUpload
        try modelContext.save()
    }

    func markAsSynced(songId: String) async throws {
        let id = songId
        let descriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == id })
        if let song = try modelContext.fetch(descriptor).first {
            song.syncStatus = .synced
            try modelContext.save()
        }
    }

    func fetchPendingUploads() async throws -> [VTSong] {
        let pendingStatus = SyncStatus.pendingUpload.rawValue
        let descriptor = FetchDescriptor<VTSong>(
            predicate: #Predicate { $0.syncStatusRaw == pendingStatus }
        )
        return try modelContext.fetch(descriptor)
    }

    func hydrateRemoteTags(_ remoteItems: [SyncedSongDTO]) async throws {
        for item in remoteItems {
            let itemId = item.id
            let descriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == itemId })
            let existingSong = try modelContext.fetch(descriptor).first
            
            if let song = existingSong {
                // Conflict Handling: If locally pending, skip it
                guard song.syncStatus != .pendingUpload else { continue }
                
                // Update tags and set to synced
                try await updateSongTags(song, with: item.tags)
                song.syncStatus = .synced
            }
        }
        try modelContext.save()
    }

    private func updateSongTags(_ song: VTSong, with tagNames: [String]) async throws {
        var updatedTags: [Tag] = []
        for tagName in tagNames {
            let name = tagName
            let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == name })
            if let existingTag = try modelContext.fetch(tagDescriptor).first {
                updatedTags.append(existingTag)
            } else {
                let newTag = Tag(name: name, hexColor: "#808080", isSystemTag: false)
                modelContext.insert(newTag)
                updatedTags.append(newTag)
            }
        }
        song.tags = updatedTags
    }
    
    func saveChanges() throws {
        try modelContext.save()
    }
}

import Foundation
import SwiftData
import Observation

@Observable
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
    
    func fetchSong(id: String) throws -> VTSong? {
        let songId = id
        let descriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == songId })
        return try modelContext.fetch(descriptor).first
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

    func saveTags(for songId: String, tags: [AnalyzedTag], syncStatus: SyncStatus = .pendingUpload) async throws {
        let id = songId
        let songDescriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == id })
        guard let song = try modelContext.fetch(songDescriptor).first else {
            throw AppError.songNotFound
        }

        var finalTags = song.tags.filter { !$0.isSystemTag } // Keep user tags
        
        for analyzedTag in tags {
            let name = analyzedTag.name
            let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == name })
            if let existingTag = try modelContext.fetch(tagDescriptor).first {
                // Update description if it changed/arrived
                if let newDesc = analyzedTag.description {
                    existingTag.tagDescription = newDesc
                }
                // Don't override isSystemTag if it's already a user tag
                // If it was already a system tag, keep it as such.
                if !finalTags.contains(where: { $0.id == existingTag.id }) {
                    finalTags.append(existingTag)
                }
            } else {
                let newTag = Tag(name: name, tagDescription: analyzedTag.description, hexColor: "#808080", isSystemTag: true)
                modelContext.insert(newTag)
                finalTags.append(newTag)
            }
        }
        
        song.tags = finalTags
        song.syncStatus = syncStatus
        try modelContext.save()
    }

    func markAsSynced(songId: String) async throws {
        let id = songId
        let descriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == id })
        guard let song = try modelContext.fetch(descriptor).first else {
            throw AppError.songNotFound
        }
        
        song.syncStatus = .synced
        try modelContext.save()
    }

    func fetchPendingUploads() async throws -> [VTSong] {
        let pendingStatus = SyncStatus.pendingUpload.rawValue
        let descriptor = FetchDescriptor<VTSong>(
            predicate: #Predicate { $0.syncStatusRaw == pendingStatus }
        )
        return try modelContext.fetch(descriptor)
    }

    func hydrateRemoteTags(_ remoteItems: [RemoteSongSyncInfo]) async throws {
        for item in remoteItems {
            do {
                let itemId = item.id
                let descriptor = FetchDescriptor<VTSong>(predicate: #Predicate { $0.id == itemId })
                let existingSong = try modelContext.fetch(descriptor).first
                
                if let song = existingSong {
                    // Conflict Handling: If locally pending, skip it
                    guard song.syncStatus != .pendingUpload else { continue }
                    
                    // Update Metadata if missing
                    if song.artworkUrl == nil { song.artworkUrl = item.artworkUrl }
                    if song.appleMusicId == nil { song.appleMusicId = item.appleMusicId }

                    // Update tags and set to synced
                    try await updateSongTags(song, with: item.tags)
                    song.syncStatus = .synced
                }
            } catch {
                print("Failed to hydrate tags for song \(item.id): \(error.localizedDescription)")
                // Continue to next item
            }
        }
        try modelContext.save()
    }
    
    func clearAllTags() async throws {
        let descriptor = FetchDescriptor<VTSong>()
        let allSongs = try modelContext.fetch(descriptor)
        for song in allSongs {
            song.tags = []
            song.syncStatus = .synced
        }
        try modelContext.save()
    }

    private func updateSongTags(_ song: VTSong, with remoteTags: [RemoteTagSyncInfo]) async throws {
        // Keep only tags that are NOT in the remote list if they are user tags? 
        // Actually, we should probably just trust the remote list for what's currently assigned,
        // but preserve the "system" vs "user" status based on what the remote says.
        
        var finalTags: [Tag] = []
        for remoteTag in remoteTags {
            let name = remoteTag.name
            let isRemoteSystem = remoteTag.type == "SYSTEM"
            
            let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == name })
            if let existingTag = try modelContext.fetch(tagDescriptor).first {
                existingTag.isSystemTag = isRemoteSystem
                finalTags.append(existingTag)
            } else {
                let newTag = Tag(name: name, tagDescription: nil, hexColor: "#808080", isSystemTag: isRemoteSystem)
                modelContext.insert(newTag)
                finalTags.append(newTag)
            }
        }
        song.tags = finalTags
    }
    
    func saveChanges() throws {
        try modelContext.save()
    }
}

import Foundation
import SwiftData

@Model
final class VTSong {
    @Attribute(.unique) var id: String // Apple Music ID / ISRC
    var appleMusicId: String? // Stable Catalog ID
    var title: String
    var artist: String
    var album: String?
    var genre: String?
    var artworkUrl: String?
    var dateAdded: Date
    
    @Relationship(deleteRule: .nullify, inverse: \Tag.songs)
    var tags: [Tag] = []
    
    var syncStatusRaw: Int = SyncStatus.synced.rawValue
    
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .synced }
        set { syncStatusRaw = newValue.rawValue }
    }
    
    init(id: String, appleMusicId: String? = nil, title: String, artist: String, album: String? = nil, genre: String? = nil, artworkUrl: String? = nil, dateAdded: Date = Date(), syncStatus: SyncStatus = .pendingUpload) {
        self.id = id
        self.appleMusicId = appleMusicId
        self.title = title
        self.artist = artist
        self.album = album
        self.genre = genre
        self.artworkUrl = artworkUrl
        self.dateAdded = dateAdded
        self.syncStatusRaw = syncStatus.rawValue
    }
}

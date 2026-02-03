import Foundation
import SwiftData

@Model
final class VTSong {
    @Attribute(.unique) var id: String // Apple Music ID / ISRC
    var title: String
    var artist: String
    var artworkUrl: String?
    var dateAdded: Date
    
    @Relationship(deleteRule: .nullify, inverse: \Tag.songs)
    var tags: [Tag] = []
    
    var syncStatusRaw: Int = SyncStatus.synced.rawValue
    
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .synced }
        set { syncStatusRaw = newValue.rawValue }
    }
    
    init(id: String, title: String, artist: String, artworkUrl: String? = nil, dateAdded: Date = Date(), syncStatus: SyncStatus = .synced) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artworkUrl = artworkUrl
        self.dateAdded = dateAdded
        self.syncStatusRaw = syncStatus.rawValue
    }
}

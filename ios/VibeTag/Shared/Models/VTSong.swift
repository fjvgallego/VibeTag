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
    var tags: [Tag]? = []
    
    init(id: String, title: String, artist: String, artworkUrl: String? = nil, dateAdded: Date = Date()) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artworkUrl = artworkUrl
        self.dateAdded = dateAdded
    }
}

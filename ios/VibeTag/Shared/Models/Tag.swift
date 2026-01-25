import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    @Attribute(.unique) var name: String
    var hexColor: String
    var isSystemTag: Bool
    
    var songs: [Song]?
    
    init(id: UUID = UUID(), name: String, hexColor: String, isSystemTag: Bool = false) {
        self.id = id
        self.name = name
        self.hexColor = hexColor
        self.isSystemTag = isSystemTag
    }
}

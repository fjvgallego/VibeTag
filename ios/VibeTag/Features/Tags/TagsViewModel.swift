import Foundation
import Observation
import SwiftData

enum TagFilter: String, CaseIterable, Identifiable {
    case all = "Todos"
    case user = "Usuario"
    case system = "Sistema"
    
    var id: String { self.rawValue }
}

@Observable
class TagsViewModel {
    var searchText: String = ""
    var selectedFilter: TagFilter = .all
    
    func filteredTags(_ allTags: [Tag]) -> [Tag] {
        var tags = allTags
        
        // Filter by type
        switch selectedFilter {
        case .user:
            tags = tags.filter { !$0.isSystemTag }
        case .system:
            tags = tags.filter { $0.isSystemTag }
        case .all:
            break
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            tags = tags.filter { $0.name.localizedStandardContains(searchText) }
        }
        
        return tags.sorted { $0.name < $1.name }
    }
}

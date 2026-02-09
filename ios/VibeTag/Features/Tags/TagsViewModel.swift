import Foundation
import Observation
import SwiftData

enum TagFilter: String, CaseIterable, Identifiable {
    case all = "Todos"
    case user = "Usuario"
    case system = "Sistema"
    
    var id: String { self.rawValue }
}

enum TagSortOption: String, CaseIterable, Identifiable {
    case name = "Nombre"
    case songCount = "Número de canciones"
    
    var id: String { self.rawValue }
}

@Observable
class TagsViewModel {
    var searchText: String = ""
    var selectedFilter: TagFilter = .all
    var selectedSort: TagSortOption = .name
    var selectedOrder: SortOrder = .ascending
    
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
        
        // Sort
        let isAscending = selectedOrder == .ascending
        
        switch selectedSort {
        case .name:
            tags.sort { 
                let comparison = $0.name.localizedCaseInsensitiveCompare($1.name)
                return isAscending ? comparison == .orderedAscending : comparison == .orderedDescending
            }
        case .songCount:
            tags.sort { 
                isAscending ? $0.songs.count < $1.songs.count : $0.songs.count > $1.songs.count
            }
        }
        
        return tags
    }
}

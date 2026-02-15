import Foundation

enum SortOrder: String, CaseIterable, Identifiable {
    case ascending = "Ascendente"
    case descending = "Descendente"
    
    var id: String { self.rawValue }
    
    var icon: String {
        self == .ascending ? "arrow.up" : "arrow.down"
    }
}

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

@MainActor
@Observable
class TagsViewModel {

    // MARK: - UI State

    var searchText: String = ""
    var selectedFilter: TagFilter = .all
    var selectedSort: TagSortOption = .name
    var selectedOrder: SortOrder = .ascending

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let syncEngine: any SyncEngine

    init(modelContext: ModelContext, syncEngine: any SyncEngine) {
        self.modelContext = modelContext
        self.syncEngine = syncEngine
    }

    // MARK: - Filtering & Sorting

    func filteredTags(_ allTags: [VibeTag.Tag]) -> [VibeTag.Tag] {
        var tags = allTags

        switch selectedFilter {
        case .user:   tags = tags.filter { !$0.isSystemTag }
        case .system: tags = tags.filter { $0.isSystemTag }
        case .all:    break
        }

        if !searchText.isEmpty {
            tags = tags.filter { $0.name.localizedStandardContains(searchText) }
        }

        let isAscending = selectedOrder == .ascending
        switch selectedSort {
        case .name:
            tags.sort {
                let cmp = $0.name.localizedCaseInsensitiveCompare($1.name)
                return isAscending ? cmp == .orderedAscending : cmp == .orderedDescending
            }
        case .songCount:
            tags.sort { isAscending ? $0.songs.count < $1.songs.count : $0.songs.count > $1.songs.count }
        }

        return tags
    }

    // MARK: - CRUD

    func createTag(name: String, hexColor: String, description: String?, existingTags: [VibeTag.Tag]) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !existingTags.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) else { return }
        let newTag = VibeTag.Tag(name: trimmedName, tagDescription: description, hexColor: hexColor)
        modelContext.insert(newTag)
        try? modelContext.save()
    }

    func updateTag(_ tag: VibeTag.Tag, name: String, hexColor: String, description: String?) {
        tag.name = name
        tag.hexColor = hexColor
        tag.tagDescription = description
        try? modelContext.save()
    }

    func deleteTag(_ tag: VibeTag.Tag) {
        for song in tag.songs {
            song.syncStatus = .pendingUpload
        }
        modelContext.delete(tag)
        try? modelContext.save()
        Task {
            await syncEngine.syncPendingChanges()
        }
    }
}

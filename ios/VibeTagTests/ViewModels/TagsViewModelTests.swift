import Testing
import SwiftData
import Foundation
@testable import VibeTag

// MARK: - Helpers

@MainActor private func makeSUT(
    syncEngine: MockSyncEngine = MockSyncEngine()
) throws -> (sut: TagsViewModel, context: ModelContext, syncEngine: MockSyncEngine, container: ModelContainer) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: VTSong.self, Tag.self, configurations: config)
    let context = container.mainContext
    let sut = TagsViewModel(modelContext: context, syncEngine: syncEngine)
    return (sut, context, syncEngine, container)
}

private func makeTag(name: String, isSystem: Bool = false, hexColor: String = "#FF2D55") -> VibeTag.Tag {
    VibeTag.Tag(name: name, hexColor: hexColor, isSystemTag: isSystem)
}

// MARK: - filteredTags

@MainActor
@Suite("TagsViewModel.filteredTags")
struct TagsViewModelFilteredTagsTests {

    @Test("Returns all tags when filter is .all and search is empty")
    func returnsAllTagsDefault() throws {
        let (sut, _, _, container) = try makeSUT()
        _ = container
        let tags = [makeTag(name: "Rock"), makeTag(name: "Pop"), makeTag(name: "IA", isSystem: true)]
        let result = sut.filteredTags(tags)
        #expect(result.count == 3)
    }

    @Test("Filters to user tags only")
    func filtersUserTags() throws {
        let (sut, _, _, container) = try makeSUT()
        _ = container
        sut.selectedFilter = .user
        let tags = [makeTag(name: "Rock"), makeTag(name: "IA", isSystem: true)]
        let result = sut.filteredTags(tags)
        #expect(result.count == 1)
        #expect(result[0].name == "Rock")
    }

    @Test("Filters to system tags only")
    func filtersSystemTags() throws {
        let (sut, _, _, container) = try makeSUT()
        _ = container
        sut.selectedFilter = .system
        let tags = [makeTag(name: "Rock"), makeTag(name: "IA", isSystem: true)]
        let result = sut.filteredTags(tags)
        #expect(result.count == 1)
        #expect(result[0].name == "IA")
    }

    @Test("Filters by search text case-insensitively")
    func filtersSearchText() throws {
        let (sut, _, _, container) = try makeSUT()
        _ = container
        sut.searchText = "rock"
        let tags = [makeTag(name: "Rock"), makeTag(name: "Pop")]
        let result = sut.filteredTags(tags)
        #expect(result.count == 1)
        #expect(result[0].name == "Rock")
    }

    @Test("Returns empty when search matches nothing")
    func returnsEmptyForNoMatch() throws {
        let (sut, _, _, container) = try makeSUT()
        _ = container
        sut.searchText = "jazz"
        let tags = [makeTag(name: "Rock"), makeTag(name: "Pop")]
        let result = sut.filteredTags(tags)
        #expect(result.isEmpty)
    }

    @Test("Sorts by name ascending")
    func sortsByNameAscending() throws {
        let (sut, _, _, container) = try makeSUT()
        _ = container
        sut.selectedSort = .name
        sut.selectedOrder = .ascending
        let tags = [makeTag(name: "Rock"), makeTag(name: "Ambient"), makeTag(name: "Pop")]
        let result = sut.filteredTags(tags)
        #expect(result.map { $0.name } == ["Ambient", "Pop", "Rock"])
    }

    @Test("Sorts by name descending")
    func sortsByNameDescending() throws {
        let (sut, _, _, container) = try makeSUT()
        _ = container
        sut.selectedSort = .name
        sut.selectedOrder = .descending
        let tags = [makeTag(name: "Rock"), makeTag(name: "Ambient"), makeTag(name: "Pop")]
        let result = sut.filteredTags(tags)
        #expect(result.map { $0.name } == ["Rock", "Pop", "Ambient"])
    }

    @Test("Combines filter and search correctly")
    func combinesFilterAndSearch() throws {
        let (sut, _, _, container) = try makeSUT()
        _ = container
        sut.selectedFilter = .user
        sut.searchText = "ro"
        let tags = [makeTag(name: "Rock"), makeTag(name: "Romantic"), makeTag(name: "IA-Rock", isSystem: true)]
        let result = sut.filteredTags(tags)
        #expect(result.count == 2)
    }
}

// MARK: - CRUD

@MainActor
@Suite("TagsViewModel.createTag")
struct TagsViewModelCreateTagTests {

    @Test("Creates a new tag and inserts it in context")
    func createsNewTag() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let existing: [VibeTag.Tag] = []

        sut.createTag(name: "Chill", hexColor: "#0000FF", description: nil, existingTags: existing)

        let descriptor = FetchDescriptor<VibeTag.Tag>()
        let allTags = try context.fetch(descriptor)
        #expect(allTags.count == 1)
        #expect(allTags[0].name == "Chill")
    }

    @Test("Trims whitespace from name before inserting")
    func trimsWhitespace() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        sut.createTag(name: "  Jazz  ", hexColor: "#FF0000", description: nil, existingTags: [])

        let descriptor = FetchDescriptor<VibeTag.Tag>()
        let allTags = try context.fetch(descriptor)
        #expect(allTags[0].name == "Jazz")
    }

    @Test("Does not create a duplicate tag (case-insensitive)")
    func doesNotCreateDuplicate() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let existing = [makeTag(name: "Rock")]

        sut.createTag(name: "rock", hexColor: "#FF0000", description: nil, existingTags: existing)

        let descriptor = FetchDescriptor<VibeTag.Tag>()
        let allTags = try context.fetch(descriptor)
        #expect(allTags.isEmpty)
    }
}

@MainActor
@Suite("TagsViewModel.updateTag")
struct TagsViewModelUpdateTagTests {

    @Test("Updates tag name, color, and description")
    func updatesTag() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let tag = makeTag(name: "Old", hexColor: "#000000")
        context.insert(tag)

        sut.updateTag(tag, name: "New", hexColor: "#FFFFFF", description: "Updated")

        #expect(tag.name == "New")
        #expect(tag.hexColor == "#FFFFFF")
        #expect(tag.tagDescription == "Updated")
    }
}

@MainActor
@Suite("TagsViewModel.deleteTag")
struct TagsViewModelDeleteTagTests {

    @Test("Deletes tag from context")
    func deletesTag() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let tag = makeTag(name: "ToDelete")
        context.insert(tag)
        try context.save()

        sut.deleteTag(tag)

        let descriptor = FetchDescriptor<VibeTag.Tag>()
        let allTags = try context.fetch(descriptor)
        #expect(allTags.isEmpty)
    }

    @Test("Marks associated songs as pending upload before deleting")
    func marksSongsPendingUpload() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let song = VTSong(id: "s1", title: "Song", artist: "Artist")
        let tag = makeTag(name: "Tagged")
        context.insert(song)
        context.insert(tag)
        song.tags = [tag]
        try context.save()

        sut.deleteTag(tag)

        #expect(song.syncStatus == .pendingUpload)
    }

    @Test("Triggers sync after deletion")
    func triggersSyncAfterDeletion() async throws {
        let syncEngine = MockSyncEngine()
        let (sut, context, _, container) = try makeSUT(syncEngine: syncEngine)
        _ = container
        let tag = makeTag(name: "ToDelete")
        context.insert(tag)
        try context.save()

        sut.deleteTag(tag)
        try await Task.sleep(for: .milliseconds(50))

        #expect(syncEngine.syncPendingChangesCallCount == 1)
    }
}

import Testing
import SwiftData
import Foundation
@testable import VibeTag

// MARK: - Helpers

@MainActor private func makeSUT(
    syncEngine: MockSyncEngine = MockSyncEngine()
) throws -> (sut: TagAssignmentViewModel, context: ModelContext, syncEngine: MockSyncEngine, container: ModelContainer) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: VTSong.self, Tag.self, configurations: config)
    let context = container.mainContext
    let sut = TagAssignmentViewModel(modelContext: context, syncEngine: syncEngine)
    return (sut, context, syncEngine, container)
}

@MainActor private func insertSong(in context: ModelContext, id: String = "s1") -> VTSong {
    let song = VTSong(id: id, title: "Song \(id)", artist: "Artist")
    context.insert(song)
    return song
}

@MainActor private func insertTag(in context: ModelContext, name: String = "Rock") -> VibeTag.Tag {
    let tag = VibeTag.Tag(name: name, hexColor: "#FF0000")
    context.insert(tag)
    return tag
}

// MARK: - toggleTag

@MainActor
@Suite("TagAssignmentViewModel.toggleTag")
struct TagAssignmentViewModelToggleTagTests {

    @Test("Adds tag to song when not already assigned")
    func addsTagToSong() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let song = insertSong(in: context)
        let tag = insertTag(in: context)

        sut.toggleTag(tag, on: song)

        #expect(song.tags.contains(tag))
    }

    @Test("Removes tag from song when already assigned")
    func removesTagFromSong() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let song = insertSong(in: context)
        let tag = insertTag(in: context)
        song.tags = [tag]

        sut.toggleTag(tag, on: song)

        #expect(!song.tags.contains(tag))
    }

    @Test("Marks song as pendingUpload after toggling")
    func marksSongPendingUpload() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let song = insertSong(in: context)
        let tag = insertTag(in: context)

        sut.toggleTag(tag, on: song)

        #expect(song.syncStatus == .pendingUpload)
    }

    @Test("Triggers sync after toggling")
    func triggersSyncAfterToggle() async throws {
        let syncEngine = MockSyncEngine()
        let (sut, context, _, container) = try makeSUT(syncEngine: syncEngine)
        _ = container
        let song = insertSong(in: context)
        let tag = insertTag(in: context)

        sut.toggleTag(tag, on: song)
        try await Task.sleep(for: .milliseconds(50))

        #expect(syncEngine.syncPendingChangesCallCount == 1)
    }
}

// MARK: - createAndToggleTag

@MainActor
@Suite("TagAssignmentViewModel.createAndToggleTag")
struct TagAssignmentViewModelCreateAndToggleTests {

    @Test("Creates a new tag and assigns it to the song")
    func createsNewTagAndAssigns() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let song = insertSong(in: context)

        sut.createAndToggleTag(name: "Chill", hexColor: "#0000FF", description: nil, on: song)

        #expect(song.tags.count == 1)
        #expect(song.tags[0].name == "Chill")
    }

    @Test("Reuses existing tag instead of creating duplicate")
    func reusesExistingTag() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let song = insertSong(in: context)
        let existing = insertTag(in: context, name: "Rock")
        try context.save()

        sut.createAndToggleTag(name: "Rock", hexColor: "#FF0000", description: nil, on: song)

        let descriptor = FetchDescriptor<VibeTag.Tag>()
        let allTags = try context.fetch(descriptor)
        #expect(allTags.count == 1)
        #expect(song.tags.contains(existing))
    }

    @Test("Trims whitespace from name before looking up or creating")
    func trimsWhitespace() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let song = insertSong(in: context)

        sut.createAndToggleTag(name: "  Jazz  ", hexColor: "#FFFF00", description: nil, on: song)

        #expect(song.tags[0].name == "Jazz")
    }

    @Test("Toggles off an existing tag when called again")
    func togglesOffWhenCalledAgain() throws {
        let (sut, context, _, container) = try makeSUT()
        _ = container
        let song = insertSong(in: context)
        let existing = insertTag(in: context, name: "Rock")
        song.tags = [existing]
        try context.save()

        sut.createAndToggleTag(name: "Rock", hexColor: "#FF0000", description: nil, on: song)

        #expect(song.tags.isEmpty)
    }
}

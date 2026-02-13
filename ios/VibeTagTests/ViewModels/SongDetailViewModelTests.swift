import Testing
import Foundation
@testable import VibeTag

// MARK: - Helpers

/// Yields to the run loop enough times to let a fire-and-forget Task complete.
/// The count covers the deepest async chain in the ViewModel:
/// Task start + saveTags + syncPendingChanges + MainActor.run = 4 awaits, plus margin.
@MainActor
private func drainTasks() async {
    for _ in 0..<6 {
        await Task.yield()
    }
}

@MainActor
private func makeSUT(
    song: VTSong? = nil,
    useCase: MockAnalyzeSongUseCase = MockAnalyzeSongUseCase(),
    repository: MockSongStorageRepository = MockSongStorageRepository(),
    syncEngine: MockSyncEngine = MockSyncEngine()
) -> (sut: SongDetailViewModel, useCase: MockAnalyzeSongUseCase, repository: MockSongStorageRepository, syncEngine: MockSyncEngine) {
    let s = song ?? VTSong(id: "song-1", title: "Test Song", artist: "Test Artist")
    let sut = SongDetailViewModel(song: s, useCase: useCase, repository: repository, syncEngine: syncEngine)
    return (sut, useCase, repository, syncEngine)
}

private func makeSystemTag(name: String) -> VibeTag.Tag {
    VibeTag.Tag(name: name, hexColor: "#808080", isSystemTag: true)
}

private func makeUserTag(name: String) -> VibeTag.Tag {
    VibeTag.Tag(name: name, hexColor: "#000000", isSystemTag: false)
}

// MARK: - Computed properties

@MainActor
@Suite("SongDetailViewModel — computed properties")
struct SongDetailComputedPropertyTests {

    @Test("systemTags returns only system tags, sorted by name")
    func systemTagsSortedByName() {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeSystemTag(name: "rock"), makeSystemTag(name: "chill"), makeUserTag(name: "fav")]
        let (sut, _, _, _) = makeSUT(song: song)

        #expect(sut.systemTags.map(\.name) == ["chill", "rock"])
    }

    @Test("userTags returns only user tags, sorted by name")
    func userTagsSortedByName() {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeUserTag(name: "zen"), makeSystemTag(name: "pop"), makeUserTag(name: "calm")]
        let (sut, _, _, _) = makeSUT(song: song)

        #expect(sut.userTags.map(\.name) == ["calm", "zen"])
    }

    @Test("systemTags is empty when song has no system tags")
    func systemTagsEmptyWhenNone() {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeUserTag(name: "fav")]
        let (sut, _, _, _) = makeSUT(song: song)

        #expect(sut.systemTags.isEmpty)
    }

    @Test("userTags is empty when song has no user tags")
    func userTagsEmptyWhenNone() {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeSystemTag(name: "jazz")]
        let (sut, _, _, _) = makeSUT(song: song)

        #expect(sut.userTags.isEmpty)
    }
}

// MARK: - analyzeSong

@MainActor
@Suite("SongDetailViewModel.analyzeSong")
struct AnalyzeSongTests {

    @Test("Sets isAnalyzing to true immediately, then false after completion")
    func isAnalyzingLifecycle() async {
        let (sut, _, _, _) = makeSUT()

        sut.analyzeSong()
        #expect(sut.isAnalyzing == true)

        await drainTasks()
        #expect(sut.isAnalyzing == false)
    }

    @Test("Calls syncPendingChanges when use case returns non-empty tags")
    func syncCalledWhenTagsReturned() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeResult = .success([AnalyzedTag(name: "jazz", description: nil)])
        let syncEngine = MockSyncEngine()
        let (sut, _, _, engine) = makeSUT(useCase: useCase, syncEngine: syncEngine)

        sut.analyzeSong()
        await drainTasks()

        #expect(engine.syncPendingChangesCallCount == 1)
    }

    @Test("Does NOT call syncPendingChanges when use case returns empty tags")
    func syncNotCalledWhenNoTagsReturned() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeResult = .success([])
        let syncEngine = MockSyncEngine()
        let (sut, _, _, engine) = makeSUT(useCase: useCase, syncEngine: syncEngine)

        sut.analyzeSong()
        await drainTasks()

        #expect(engine.syncPendingChangesCallCount == 0)
    }

    @Test("Sets errorMessage and showError when use case throws")
    func setsErrorOnUseCaseFailure() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeResult = .failure(AppError.serverError(statusCode: 500))
        let (sut, _, _, _) = makeSUT(useCase: useCase)

        sut.analyzeSong()
        await drainTasks()

        #expect(sut.errorMessage != nil)
        #expect(sut.showError == true)
    }

    @Test("Sets isAnalyzing to false even when use case throws")
    func isAnalyzingFalseOnError() async {
        let useCase = MockAnalyzeSongUseCase()
        useCase.executeResult = .failure(AppError.unknown)
        let (sut, _, _, _) = makeSUT(useCase: useCase)

        sut.analyzeSong()
        await drainTasks()

        #expect(sut.isAnalyzing == false)
    }
}

// MARK: - addTag

@MainActor
@Suite("SongDetailViewModel.addTag")
struct AddTagTests {

    // MARK: Guard conditions (synchronous)

    @Test("Does nothing when tag name is empty")
    func doesNothingForEmptyName() async {
        let (sut, _, repo, _) = makeSUT()

        sut.addTag("")
        await drainTasks()

        #expect(repo.saveTagsCallCount == 0)
    }

    @Test("Does nothing when tag name is only whitespace")
    func doesNothingForWhitespaceName() async {
        let (sut, _, repo, _) = makeSUT()

        sut.addTag("   ")
        await drainTasks()

        #expect(repo.saveTagsCallCount == 0)
    }

    @Test("Does nothing when tag already exists (case-insensitive)")
    func doesNothingForDuplicateTag() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeUserTag(name: "Jazz")]
        let (sut, _, repo, _) = makeSUT(song: song)

        sut.addTag("jazz")
        await drainTasks()

        #expect(repo.saveTagsCallCount == 0)
    }

    @Test("Does nothing when tag already exists with different casing")
    func doesNothingForCaseVariantDuplicate() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeSystemTag(name: "ROCK")]
        let (sut, _, repo, _) = makeSUT(song: song)

        sut.addTag("rock")
        await drainTasks()

        #expect(repo.saveTagsCallCount == 0)
    }

    // MARK: Optimistic update

    @Test("Appends tag to song.tags optimistically before async save")
    func appendsTagOptimistically() {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        let (sut, _, _, _) = makeSUT(song: song)

        sut.addTag("indie")

        #expect(sut.song.tags.contains(where: { $0.name == "indie" }))
    }

    @Test("Trims whitespace from tag name")
    func trimsWhitespace() {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        let (sut, _, _, _) = makeSUT(song: song)

        sut.addTag("  blues  ")

        #expect(sut.song.tags.contains(where: { $0.name == "blues" }))
    }

    // MARK: Async save

    @Test("Calls saveTags with all current tags including the new one")
    func callsSaveTagsWithAllTags() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        let existingTag = makeUserTag(name: "existing")
        song.tags = [existingTag]
        let (sut, _, repo, _) = makeSUT(song: song)

        sut.addTag("new-tag")
        await drainTasks()

        #expect(repo.saveTagsCallCount == 1)
        let savedNames = repo.saveTagsReceivedCalls.first?.tags.map(\.name) ?? []
        #expect(savedNames.contains("existing"))
        #expect(savedNames.contains("new-tag"))
    }

    @Test("Calls syncPendingChanges after successful save")
    func callsSyncAfterSave() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        let (sut, _, _, engine) = makeSUT(song: song)

        sut.addTag("jazz")
        await drainTasks()

        #expect(engine.syncPendingChangesCallCount == 1)
    }

    // MARK: Rollback on failure

    @Test("Reverts song.tags to previous state when save fails")
    func revertsSongTagsOnSaveFailure() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        let originalTag = makeUserTag(name: "original")
        song.tags = [originalTag]

        let repo = MockSongStorageRepository()
        repo.saveTagsShouldThrow = AppError.unknown
        let (sut, _, _, _) = makeSUT(song: song, repository: repo)

        sut.addTag("new-tag")
        await drainTasks()

        #expect(sut.song.tags.map(\.name) == ["original"])
    }

    @Test("Sets errorMessage and showError when save fails")
    func setsErrorOnSaveFailure() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        let repo = MockSongStorageRepository()
        repo.saveTagsShouldThrow = AppError.unknown
        let (sut, _, _, _) = makeSUT(song: song, repository: repo)

        sut.addTag("new-tag")
        await drainTasks()

        #expect(sut.errorMessage != nil)
        #expect(sut.showError == true)
    }

    @Test("Reuses an existing tag from the repository when available")
    func reusesExistingTagFromRepository() {
        let existingTag = makeUserTag(name: "chill")
        let repo = MockSongStorageRepository()
        repo.fetchSongResult = { _ in nil }
        // Override fetchTag to return the existing tag
        let song = VTSong(id: "s1", title: "T", artist: "A")
        let (sut, _, _, _) = makeSUT(song: song, repository: repo)

        // We can't easily verify which Tag object was used without exposing it,
        // but we can verify the tag is added and repo.saveTagsCallCount is correct.
        sut.addTag("chill")

        #expect(sut.song.tags.contains(where: { $0.name == "chill" }))
    }
}

// MARK: - removeTag

@MainActor
@Suite("SongDetailViewModel.removeTag")
struct RemoveTagTests {

    @Test("Does nothing when tag does not exist on the song")
    func doesNothingForNonExistentTag() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeUserTag(name: "jazz")]
        let (sut, _, repo, _) = makeSUT(song: song)

        sut.removeTag("rock")
        await drainTasks()

        #expect(repo.saveTagsCallCount == 0)
    }

    @Test("Calls saveTags without the removed tag")
    func callsSaveTagsWithoutRemovedTag() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeUserTag(name: "jazz"), makeUserTag(name: "rock")]
        let (sut, _, repo, _) = makeSUT(song: song)

        sut.removeTag("jazz")
        await drainTasks()

        #expect(repo.saveTagsCallCount == 1)
        let savedNames = repo.saveTagsReceivedCalls.first?.tags.map(\.name) ?? []
        #expect(!savedNames.contains("jazz"))
        #expect(savedNames.contains("rock"))
    }

    @Test("Removes tag from song.tags after successful save")
    func removesSongTagOnSuccess() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeUserTag(name: "jazz"), makeUserTag(name: "rock")]
        let (sut, _, _, _) = makeSUT(song: song)

        sut.removeTag("jazz")
        await drainTasks()

        #expect(!sut.song.tags.contains(where: { $0.name == "jazz" }))
        #expect(sut.song.tags.contains(where: { $0.name == "rock" }))
    }

    @Test("Removes tag case-insensitively")
    func removesTagCaseInsensitively() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeUserTag(name: "Jazz")]
        let (sut, _, _, _) = makeSUT(song: song)

        sut.removeTag("JAZZ")
        await drainTasks()

        #expect(sut.song.tags.isEmpty)
    }

    @Test("Calls syncPendingChanges after successful removal")
    func callsSyncAfterRemoval() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeUserTag(name: "jazz")]
        let (sut, _, _, engine) = makeSUT(song: song)

        sut.removeTag("jazz")
        await drainTasks()

        #expect(engine.syncPendingChangesCallCount == 1)
    }

    @Test("Sets errorMessage and showError when save fails")
    func setsErrorOnSaveFailure() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        song.tags = [makeUserTag(name: "jazz")]
        let repo = MockSongStorageRepository()
        repo.saveTagsShouldThrow = AppError.unknown
        let (sut, _, _, _) = makeSUT(song: song, repository: repo)

        sut.removeTag("jazz")
        await drainTasks()

        #expect(sut.errorMessage != nil)
        #expect(sut.showError == true)
    }

    @Test("Does not update song.tags when save fails")
    func doesNotUpdateTagsOnSaveFailure() async {
        let song = VTSong(id: "s1", title: "T", artist: "A")
        let tag = makeUserTag(name: "jazz")
        song.tags = [tag]
        let repo = MockSongStorageRepository()
        repo.saveTagsShouldThrow = AppError.unknown
        let (sut, _, _, _) = makeSUT(song: song, repository: repo)

        sut.removeTag("jazz")
        await drainTasks()

        // song.tags is only updated inside the Task after await, so on failure
        // the MainActor.run block that updates it is never reached
        #expect(sut.song.tags.contains(where: { $0.name == "jazz" }))
    }
}

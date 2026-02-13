import Testing
import Foundation
import SwiftData
@testable import VibeTag

// MARK: - In-memory container helper

/// Holds all three objects so none of them is released early.
/// Tests that receive an `Env` keep the `ModelContainer` alive for their full duration.
@MainActor
private struct Env {
    let sut: LocalSongStorageRepositoryImpl
    let context: ModelContext
    // Kept alive by this struct — do NOT remove even if the compiler calls it "unused".
    private let container: ModelContainer

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: VTSong.self, VibeTag.Tag.self, configurations: config)
        context = container.mainContext
        sut = LocalSongStorageRepositoryImpl(modelContext: context)
    }
}

// MARK: - Model factories

private func makeSong(
    id: String = "song-1",
    title: String = "Test Song",
    artist: String = "Test Artist",
    syncStatus: SyncStatus = .synced,
    artworkUrl: String? = nil,
    appleMusicId: String? = nil
) -> VTSong {
    let song = VTSong(id: id, title: title, artist: artist, syncStatus: syncStatus)
    song.artworkUrl = artworkUrl
    song.appleMusicId = appleMusicId
    return song
}

private func makeSystemTag(name: String, description: String? = nil, color: String = "#808080") -> VibeTag.Tag {
    VibeTag.Tag(name: name, tagDescription: description, hexColor: color, isSystemTag: true)
}

private func makeUserTag(name: String, color: String = "#000000") -> VibeTag.Tag {
    VibeTag.Tag(name: name, hexColor: color, isSystemTag: false)
}

private func makeRemoteSong(
    id: String,
    appleMusicId: String? = nil,
    artworkUrl: String? = nil,
    tags: [RemoteTagSyncInfo] = []
) -> RemoteSongSyncInfo {
    RemoteSongSyncInfo(id: id, appleMusicId: appleMusicId, artworkUrl: artworkUrl, tags: tags)
}

private func makeRemoteTag(name: String, type: String = "SYSTEM", color: String? = nil) -> RemoteTagSyncInfo {
    RemoteTagSyncInfo(name: name, type: type, color: color)
}

// MARK: - saveTags

@MainActor
@Suite("LocalSongStorageRepository.saveTags")
struct SaveTagsTests {

    @Test("Throws songNotFound when song does not exist")
    func throwsSongNotFoundForMissingSong() async throws {
        let env = try Env()
        let sut = env.sut

        await #expect(throws: AppError.self) {
            try await sut.saveTags(for: "ghost-id", tags: [], syncStatus: .synced)
        }
    }

    @Test("Creates new Tag entities for each AnalyzedTag")
    func createsNewTagsForEachAnalyzedTag() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong()
        context.insert(song)

        try await sut.saveTags(
            for: "song-1",
            tags: [AnalyzedTag(name: "chill", description: nil), AnalyzedTag(name: "electronic", description: nil)],
            syncStatus: .synced
        )

        let allTags = try context.fetch(FetchDescriptor<VibeTag.Tag>())
        #expect(allTags.count == 2)
        #expect(Set(allTags.map(\.name)) == ["chill", "electronic"])
    }

    @Test("New tags are created as system tags")
    func newTagsAreSystemTags() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        context.insert(makeSong())

        try await sut.saveTags(for: "song-1", tags: [AnalyzedTag(name: "jazz", description: nil)], syncStatus: .synced)

        let tag = try context.fetch(FetchDescriptor<VibeTag.Tag>()).first
        #expect(tag?.isSystemTag == true)
    }

    @Test("New tags get the default grey color")
    func newTagsGetDefaultColor() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        context.insert(makeSong())

        try await sut.saveTags(for: "song-1", tags: [AnalyzedTag(name: "pop", description: nil)], syncStatus: .synced)

        let tag = try context.fetch(FetchDescriptor<VibeTag.Tag>()).first
        #expect(tag?.hexColor == "#808080")
    }

    @Test("Sets song syncStatus to the provided value")
    func setsSyncStatusOnSong() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(syncStatus: .pendingUpload)
        context.insert(song)

        try await sut.saveTags(for: "song-1", tags: [], syncStatus: .synced)

        #expect(song.syncStatus == .synced)
    }

    @Test("Preserves existing user tags")
    func preservesUserTags() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let userTag = makeUserTag(name: "favourites")
        let song = makeSong()
        context.insert(userTag)
        context.insert(song)
        song.tags = [userTag]

        try await sut.saveTags(for: "song-1", tags: [AnalyzedTag(name: "rock", description: nil)], syncStatus: .synced)

        #expect(song.tags.contains(where: { $0.name == "favourites" }))
    }

    @Test("Replaces previous system tags with new ones")
    func replacesPreviousSystemTags() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let oldSystemTag = makeSystemTag(name: "old-tag")
        let song = makeSong()
        context.insert(oldSystemTag)
        context.insert(song)
        song.tags = [oldSystemTag]

        try await sut.saveTags(for: "song-1", tags: [AnalyzedTag(name: "new-tag", description: nil)], syncStatus: .synced)

        #expect(!song.tags.contains(where: { $0.name == "old-tag" }))
        #expect(song.tags.contains(where: { $0.name == "new-tag" }))
    }

    @Test("Reuses an existing tag with the same name instead of creating a duplicate")
    func reusesExistingTagByName() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let existingTag = makeSystemTag(name: "chill")
        let song = makeSong()
        context.insert(existingTag)
        context.insert(song)

        try await sut.saveTags(for: "song-1", tags: [AnalyzedTag(name: "chill", description: nil)], syncStatus: .synced)

        let allTags = try context.fetch(FetchDescriptor<VibeTag.Tag>())
        #expect(allTags.count == 1, "Should reuse the existing tag, not create a second one")
    }

    @Test("Updates description of an existing tag when a new description is provided")
    func updatesDescriptionOfExistingTag() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let existingTag = makeSystemTag(name: "chill", description: "Old description")
        let song = makeSong()
        context.insert(existingTag)
        context.insert(song)

        try await sut.saveTags(for: "song-1", tags: [AnalyzedTag(name: "chill", description: "New description")], syncStatus: .synced)

        #expect(existingTag.tagDescription == "New description")
    }

    @Test("Does not update description of an existing tag when new description is nil")
    func doesNotOverwriteDescriptionWithNil() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let existingTag = makeSystemTag(name: "chill", description: "Keep me")
        let song = makeSong()
        context.insert(existingTag)
        context.insert(song)

        try await sut.saveTags(for: "song-1", tags: [AnalyzedTag(name: "chill", description: nil)], syncStatus: .synced)

        #expect(existingTag.tagDescription == "Keep me")
    }

    @Test("Does not add a duplicate if the existing tag is already in finalTags")
    func doesNotAddDuplicateExistingTag() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let existingTag = makeSystemTag(name: "chill")
        let song = makeSong()
        context.insert(existingTag)
        context.insert(song)
        song.tags = [existingTag]  // already assigned

        try await sut.saveTags(
            for: "song-1",
            tags: [AnalyzedTag(name: "chill", description: nil)],
            syncStatus: .synced
        )

        // The system-tag filter strips it first, then re-adds it once
        #expect(song.tags.filter({ $0.name == "chill" }).count == 1)
    }

    @Test("Assigns the saved tags to the song")
    func assignsTagsToSong() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong()
        context.insert(song)

        try await sut.saveTags(
            for: "song-1",
            tags: [AnalyzedTag(name: "blues", description: nil)],
            syncStatus: .synced
        )

        #expect(song.tags.contains(where: { $0.name == "blues" }))
    }
}

// MARK: - markAsSynced

@MainActor
@Suite("LocalSongStorageRepository.markAsSynced")
struct MarkAsSyncedTests {

    @Test("Throws songNotFound when song does not exist")
    func throwsForMissingSong() async throws {
        let env = try Env()
        let sut = env.sut

        await #expect(throws: AppError.self) {
            try await sut.markAsSynced(songId: "ghost")
        }
    }

    @Test("Sets syncStatus to .synced")
    func setsSyncStatusToSynced() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(syncStatus: .pendingUpload)
        context.insert(song)

        try await sut.markAsSynced(songId: "song-1")

        #expect(song.syncStatus == .synced)
    }
}

// MARK: - fetchPendingUploads

@MainActor
@Suite("LocalSongStorageRepository.fetchPendingUploads")
struct FetchPendingUploadsTests {

    @Test("Returns only songs with pendingUpload status")
    func returnsOnlyPendingUploadSongs() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        context.insert(makeSong(id: "s1", syncStatus: .pendingUpload))
        context.insert(makeSong(id: "s2", syncStatus: .synced))
        context.insert(makeSong(id: "s3", syncStatus: .pendingUpload))

        let result = try await sut.fetchPendingUploads()

        #expect(result.count == 2)
        #expect(Set(result.map(\.id)) == ["s1", "s3"])
    }

    @Test("Returns empty array when no songs are pending")
    func returnsEmptyWhenNoPending() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        context.insert(makeSong(id: "s1", syncStatus: .synced))

        let result = try await sut.fetchPendingUploads()

        #expect(result.isEmpty)
    }
}

// MARK: - hydrateRemoteTags

@MainActor
@Suite("LocalSongStorageRepository.hydrateRemoteTags")
struct HydrateRemoteTagsTests {

    // MARK: Conflict resolution

    @Test("Skips songs with pendingUpload status")
    func skipsPendingUploadSongs() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1", syncStatus: .pendingUpload)
        context.insert(song)

        let remoteTag = makeRemoteTag(name: "pop")
        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", tags: [remoteTag])])

        #expect(song.tags.isEmpty, "pendingUpload song must not be modified")
        #expect(song.syncStatus == .pendingUpload, "sync status must remain pendingUpload")
    }

    // MARK: Metadata updates

    @Test("Updates artworkUrl when it is nil locally")
    func updatesArtworkUrlWhenMissing() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1", artworkUrl: nil)
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", artworkUrl: "https://art.example.com/cover.jpg")])

        #expect(song.artworkUrl == "https://art.example.com/cover.jpg")
    }

    @Test("Does not overwrite artworkUrl when already set")
    func doesNotOverwriteExistingArtworkUrl() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1", artworkUrl: "https://existing.com/art.jpg")
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", artworkUrl: "https://new.com/art.jpg")])

        #expect(song.artworkUrl == "https://existing.com/art.jpg")
    }

    @Test("Updates appleMusicId when it is nil locally")
    func updatesAppleMusicIdWhenMissing() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1", appleMusicId: nil)
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", appleMusicId: "am-999")])

        #expect(song.appleMusicId == "am-999")
    }

    @Test("Does not overwrite appleMusicId when already set")
    func doesNotOverwriteExistingAppleMusicId() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1", appleMusicId: "am-original")
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", appleMusicId: "am-new")])

        #expect(song.appleMusicId == "am-original")
    }

    // MARK: Tag sync

    @Test("Sets song syncStatus to .synced after hydration")
    func setsSyncStatusToSynced() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1", syncStatus: .synced)
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1")])

        #expect(song.syncStatus == .synced)
    }

    @Test("Creates new tags from remote data")
    func createsNewTagsFromRemote() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1")
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", tags: [makeRemoteTag(name: "indie")])])

        #expect(song.tags.contains(where: { $0.name == "indie" }))
    }

    @Test("Sets isSystemTag = true when remote type is SYSTEM")
    func setsSystemTagForSystemType() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1")
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", tags: [makeRemoteTag(name: "chill", type: "SYSTEM")])])

        #expect(song.tags.first?.isSystemTag == true)
    }

    @Test("Sets isSystemTag = false when remote type is USER")
    func setsUserTagForUserType() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1")
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", tags: [makeRemoteTag(name: "favourites", type: "USER")])])

        #expect(song.tags.first?.isSystemTag == false)
    }

    @Test("Uses remote color when provided")
    func usesRemoteColorWhenProvided() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1")
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", tags: [makeRemoteTag(name: "pop", color: "#FF5733")])])

        #expect(song.tags.first?.hexColor == "#FF5733")
    }

    @Test("Uses default grey color when remote color is nil")
    func usesDefaultColorWhenRemoteColorIsNil() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "s1")
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", tags: [makeRemoteTag(name: "pop", color: nil)])])

        #expect(song.tags.first?.hexColor == "#808080")
    }

    @Test("Reuses an existing local tag and updates its isSystemTag flag")
    func reusesExistingTagAndUpdatesSystemFlag() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let existingTag = makeUserTag(name: "chill")  // was user locally
        let song = makeSong(id: "s1")
        context.insert(existingTag)
        context.insert(song)
        song.tags = [existingTag]

        // Remote says it's a SYSTEM tag
        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", tags: [makeRemoteTag(name: "chill", type: "SYSTEM")])])

        let allTags = try context.fetch(FetchDescriptor<VibeTag.Tag>())
        #expect(allTags.count == 1, "Should reuse existing tag, not create a new one")
        #expect(allTags.first?.isSystemTag == true)
    }

    @Test("Updates color of an existing tag when remote provides a color")
    func updatesColorOfExistingTag() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let existingTag = makeSystemTag(name: "rock", color: "#000000")
        let song = makeSong(id: "s1")
        context.insert(existingTag)
        context.insert(song)

        try await sut.hydrateRemoteTags([makeRemoteSong(id: "s1", tags: [makeRemoteTag(name: "rock", color: "#FF0000")])])

        #expect(existingTag.hexColor == "#FF0000")
    }

    @Test("Silently skips remote items whose song is not in local DB")
    func silentlySkipsUnknownSongs() async throws {
        let env = try Env()
        let sut = env.sut

        // Should not throw
        try await sut.hydrateRemoteTags([makeRemoteSong(id: "unknown-id")])
    }

    @Test("Continues processing remaining items after a per-item error")
    func continuesAfterPerItemError() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        // Only insert the second song; first will not be found but should not abort the batch
        let song2 = makeSong(id: "s2")
        context.insert(song2)

        try await sut.hydrateRemoteTags([
            makeRemoteSong(id: "ghost"),          // not in DB → skipped
            makeRemoteSong(id: "s2", tags: [makeRemoteTag(name: "pop")])
        ])

        #expect(song2.tags.contains(where: { $0.name == "pop" }))
    }
}

// MARK: - clearAllTags

@MainActor
@Suite("LocalSongStorageRepository.clearAllTags")
struct ClearAllTagsTests {

    @Test("Removes all tags from every song")
    func removesAllTagsFromSongs() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let tag = makeSystemTag(name: "chill")
        let song = makeSong()
        context.insert(tag)
        context.insert(song)
        song.tags = [tag]

        try await sut.clearAllTags()

        #expect(song.tags.isEmpty)
    }

    @Test("Deletes all Tag entities from the store")
    func deletesAllTagEntities() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        context.insert(makeSystemTag(name: "rock"))
        context.insert(makeUserTag(name: "favourites"))

        try await sut.clearAllTags()

        let remaining = try context.fetch(FetchDescriptor<VibeTag.Tag>())
        #expect(remaining.isEmpty)
    }

    @Test("Resets syncStatus of all songs to .synced")
    func resetsSyncStatusToSynced() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(syncStatus: .pendingUpload)
        context.insert(song)

        try await sut.clearAllTags()

        #expect(song.syncStatus == .synced)
    }
}

// MARK: - Basic CRUD

@MainActor
@Suite("LocalSongStorageRepository - Basic CRUD")
struct BasicCRUDTests {

    @Test("fetchAllSongs returns all inserted songs")
    func fetchAllSongsReturnsAllInserted() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        context.insert(makeSong(id: "s1"))
        context.insert(makeSong(id: "s2"))

        let result = try sut.fetchAllSongs()

        #expect(result.count == 2)
    }

    @Test("fetchSong returns the song with the matching id")
    func fetchSongReturnMatchingId() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        context.insert(makeSong(id: "target"))
        context.insert(makeSong(id: "other"))

        let result = try sut.fetchSong(id: "target")

        #expect(result?.id == "target")
    }

    @Test("fetchSong returns nil for unknown id")
    func fetchSongReturnsNilForUnknownId() async throws {
        let env = try Env()
        let sut = env.sut

        let result = try sut.fetchSong(id: "ghost")

        #expect(result == nil)
    }

    @Test("fetchTag returns the tag with the matching name")
    func fetchTagReturnsMatchingName() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        context.insert(makeSystemTag(name: "jazz"))

        let result = try sut.fetchTag(name: "jazz")

        #expect(result?.name == "jazz")
    }

    @Test("fetchTag returns nil for unknown name")
    func fetchTagReturnsNilForUnknownName() async throws {
        let env = try Env()
        let sut = env.sut

        let result = try sut.fetchTag(name: "ghost")

        #expect(result == nil)
    }

    @Test("songExists returns true when song is present")
    func songExistsReturnsTrueWhenPresent() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        context.insert(makeSong(id: "s1"))

        #expect(try sut.songExists(id: "s1") == true)
    }

    @Test("songExists returns false when song is absent")
    func songExistsReturnsFalseWhenAbsent() async throws {
        let env = try Env()
        let sut = env.sut

        #expect(try sut.songExists(id: "ghost") == false)
    }

    @Test("saveSong inserts a song into the store")
    func saveSongInsertsIntoStore() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "new-song")

        sut.saveSong(song)

        let all = try context.fetch(FetchDescriptor<VTSong>())
        #expect(all.contains(where: { $0.id == "new-song" }))
    }

    @Test("deleteSong removes a song from the store")
    func deleteSongRemovesFromStore() async throws {
        let env = try Env()
        let sut = env.sut
        let context = env.context
        let song = makeSong(id: "to-delete")
        context.insert(song)

        sut.deleteSong(song)
        try sut.saveChanges()

        let all = try context.fetch(FetchDescriptor<VTSong>())
        #expect(!all.contains(where: { $0.id == "to-delete" }))
    }
}

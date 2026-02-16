import Testing
import Foundation
@testable import VibeTag

// MARK: - Helpers

/// Creates a VTSong without a SwiftData ModelContext (sufficient for use-case logic tests).
private func makeSong(
    id: String = "song-1",
    title: String = "Test Song",
    artist: String = "Test Artist",
    tags: [VibeTag.Tag] = []
) -> VTSong {
    let song = VTSong(id: id, title: title, artist: artist)
    song.tags = tags
    return song
}

private func makeSystemTag(name: String = "chill") -> VibeTag.Tag {
    VibeTag.Tag(name: name, hexColor: "#FFFFFF", isSystemTag: true)
}

private func makeUserTag(name: String = "favourites") -> VibeTag.Tag {
    VibeTag.Tag(name: name, hexColor: "#000000", isSystemTag: false)
}

// MARK: - execute (single song)

@MainActor
@Suite("AnalyzeSongUseCase.execute")
struct AnalyzeSongUseCaseExecuteTests {

    // MARK: Cache-hit

    @Test("Returns cached system tags without calling remote")
    func returnsCachedSystemTags() async throws {
        let systemTag = makeSystemTag(name: "chill")
        let song = makeSong(tags: [systemTag])

        let remote = MockSongRepository()
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        let result = try await sut.execute(song: song)

        #expect(result.count == 1)
        #expect(result[0].name == "chill")
        #expect(remote.fetchAnalysisCallCount == 0, "Remote must NOT be called when system tags are cached")
        #expect(local.saveTagsCallCount == 0, "saveTags must NOT be called on a cache-hit")
    }

    @Test("Maps system tag description correctly from cache")
    func mapsTagDescriptionFromCache() async throws {
        let tag = VibeTag.Tag(name: "upbeat", tagDescription: "High-energy songs", hexColor: "#FF0000", isSystemTag: true)
        let song = makeSong(tags: [tag])

        let sut = AnalyzeSongUseCase(remoteRepository: MockSongRepository(), localRepository: MockSongStorageRepository())

        let result = try await sut.execute(song: song)

        #expect(result[0].description == "High-energy songs")
    }

    @Test("User-only tags are NOT treated as a cache-hit")
    func userTagsDoNotPreventRemoteCall() async throws {
        let userTag = makeUserTag()
        let song = makeSong(tags: [userTag])

        let remote = MockSongRepository()
        remote.fetchAnalysisResult = .success([AnalyzedTag(name: "electronic", description: nil)])
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        _ = try await sut.execute(song: song)

        #expect(remote.fetchAnalysisCallCount == 1, "Remote must be called when the song has only user tags")
    }

    @Test("Song with no tags calls remote and saves result")
    func noTagsCallsRemoteAndSaves() async throws {
        let song = makeSong()
        let remote = MockSongRepository()
        remote.fetchAnalysisResult = .success([AnalyzedTag(name: "jazz", description: "Smooth jazz")])
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        let result = try await sut.execute(song: song)

        #expect(result.count == 1)
        #expect(result[0].name == "jazz")
        #expect(remote.fetchAnalysisCallCount == 1)
        #expect(local.saveTagsCallCount == 1)
    }

    @Test("Saves tags with syncStatus .synced")
    func saveTagsUsesSyncedStatus() async throws {
        let song = makeSong()
        let remote = MockSongRepository()
        remote.fetchAnalysisResult = .success([AnalyzedTag(name: "pop", description: nil)])
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        _ = try await sut.execute(song: song)

        #expect(local.saveTagsReceivedCalls.first?.syncStatus == .synced)
    }

    @Test("Saves tags for the correct song ID")
    func saveTagsUsesCorrectSongId() async throws {
        let song = makeSong(id: "abc-123")
        let remote = MockSongRepository()
        remote.fetchAnalysisResult = .success([AnalyzedTag(name: "rock", description: nil)])
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        _ = try await sut.execute(song: song)

        #expect(local.saveTagsReceivedCalls.first?.songId == "abc-123")
    }

    @Test("Propagates remote error to caller")
    func propagatesRemoteError() async throws {
        let song = makeSong()
        let remote = MockSongRepository()
        remote.fetchAnalysisResult = .failure(AppError.serverError(statusCode: 500))
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        await #expect(throws: AppError.self) {
            _ = try await sut.execute(song: song)
        }
    }

    @Test("Does not save tags when remote throws")
    func doesNotSaveOnRemoteError() async throws {
        let song = makeSong()
        let remote = MockSongRepository()
        remote.fetchAnalysisResult = .failure(AppError.unknown)
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        _ = try? await sut.execute(song: song)

        #expect(local.saveTagsCallCount == 0)
    }

    @Test("Propagates saveTags error to caller")
    func propagatesSaveTagsError() async throws {
        let song = makeSong()
        let remote = MockSongRepository()
        remote.fetchAnalysisResult = .success([AnalyzedTag(name: "indie", description: nil)])
        let local = MockSongStorageRepository()
        local.saveTagsShouldThrow = AppError.unknown
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        await #expect(throws: AppError.self) {
            _ = try await sut.execute(song: song)
        }
    }

    @Test("Returns remote tags (not local state) after save")
    func returnsRemoteTags() async throws {
        let song = makeSong()
        let expectedTags = [
            AnalyzedTag(name: "indie", description: "Indie vibes"),
            AnalyzedTag(name: "mellow", description: nil)
        ]
        let remote = MockSongRepository()
        remote.fetchAnalysisResult = .success(expectedTags)
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        let result = try await sut.execute(song: song)

        #expect(result.map(\.name) == ["indie", "mellow"])
    }
}

// MARK: - executeBatch

@MainActor
@Suite("AnalyzeSongUseCase.executeBatch")
struct AnalyzeSongUseCaseBatchTests {

    // MARK: Filtering

    @Test("Songs with system tags are excluded from analysis")
    func songsWithSystemTagsAreSkipped() async throws {
        let alreadyAnalyzed = makeSong(id: "s1", tags: [makeSystemTag()])
        let needsAnalysis = makeSong(id: "s2")

        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [.success([SongAnalysisResult(songId: "s2", tags: [])])]
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        try await sut.executeBatch(songs: [alreadyAnalyzed, needsAnalysis], onProgress: { _, _ in })

        let sentSongs = remote.fetchBatchAnalysisLastSongs
        #expect(!sentSongs.contains(where: { $0.id == "s1" }))
        #expect(sentSongs.contains(where: { $0.id == "s2" }))
    }

    @Test("Songs with only user tags are included in analysis")
    func songsWithUserTagsAreIncluded() async throws {
        let song = makeSong(id: "s1", tags: [makeUserTag()])

        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [.success([])]
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        try await sut.executeBatch(songs: [song], onProgress: { _, _ in })

        #expect(remote.fetchBatchAnalysisCallCount == 1)
    }

    // MARK: Empty input

    @Test("Empty input calls onProgress(0, 0) and does not call remote")
    func emptyInputCallsProgressWithZero() async throws {
        var progressArgs: (Int, Int)?
        let remote = MockSongRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        try await sut.executeBatch(songs: [], onProgress: { current, total in
            progressArgs = (current, total)
        })

        let (current, total) = try #require(progressArgs)
        #expect(current == 0)
        #expect(total == 0)
        #expect(remote.fetchBatchAnalysisCallCount == 0)
    }

    @Test("All-already-analyzed input calls onProgress(0, 0) and does not call remote")
    func allAnalyzedInputCallsProgressWithZero() async throws {
        let songs = [makeSong(tags: [makeSystemTag()]), makeSong(id: "s2", tags: [makeSystemTag(name: "pop")])]
        var progressArgs: (Int, Int)?
        let remote = MockSongRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        try await sut.executeBatch(songs: songs, onProgress: { current, total in
            progressArgs = (current, total)
        })

        let (current, total) = try #require(progressArgs)
        #expect(current == 0)
        #expect(total == 0)
        #expect(remote.fetchBatchAnalysisCallCount == 0)
    }

    // MARK: Chunking

    @Test("Songs are split into chunks of 20")
    func songsAreSplitIntoChunksOf20() async throws {
        // 21 songs → 2 chunks (20 + 1)
        let songs = (1...21).map { makeSong(id: "s\($0)") }

        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [
            .success([]),
            .success([])
        ]
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        try await sut.executeBatch(songs: songs, onProgress: { _, _ in })

        #expect(remote.fetchBatchAnalysisCallCount == 2)
    }

    @Test("Exactly 20 songs produces a single chunk")
    func exactly20SongsProducesOneChunk() async throws {
        let songs = (1...20).map { makeSong(id: "s\($0)") }
        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [.success([])]
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        try await sut.executeBatch(songs: songs, onProgress: { _, _ in })

        #expect(remote.fetchBatchAnalysisCallCount == 1)
    }

    // MARK: Progress reporting

    @Test("onProgress is called once per chunk with cumulative counts")
    func progressIsReportedPerChunk() async throws {
        // 3 songs → 1 chunk of 3
        let songs = (1...3).map { makeSong(id: "s\($0)") }
        var progressCalls: [(Int, Int)] = []
        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [.success([])]
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        try await sut.executeBatch(songs: songs, onProgress: { current, total in
            progressCalls.append((current, total))
        })

        #expect(progressCalls.count == 1)
        #expect(progressCalls[0] == (3, 3))
    }

    @Test("onProgress reports cumulative count across multiple chunks")
    func progressCumulatesAcrossChunks() async throws {
        // 25 songs → chunks of 20 + 5
        let songs = (1...25).map { makeSong(id: "s\($0)") }
        var progressCalls: [(Int, Int)] = []
        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [.success([]), .success([])]
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        try await sut.executeBatch(songs: songs, onProgress: { current, total in
            progressCalls.append((current, total))
        })

        #expect(progressCalls.count == 2)
        #expect(progressCalls[0] == (20, 25))
        #expect(progressCalls[1] == (25, 25))
    }

    // MARK: Partial failures

    @Test("A single failing chunk does not prevent other chunks from being processed")
    func singleFailingChunkDoesNotStopOtherChunks() async throws {
        let songs = (1...25).map { makeSong(id: "s\($0)") }

        let remote = MockSongRepository()
        // First chunk fails, second succeeds
        remote.fetchBatchAnalysisResults = [
            .failure(AppError.serverError(statusCode: 503)),
            .success([])
        ]
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        // Should NOT throw because at least one chunk succeeded
        try await sut.executeBatch(songs: songs, onProgress: { _, _ in })

        #expect(remote.fetchBatchAnalysisCallCount == 2)
    }

    @Test("Does not throw when at least one chunk succeeds")
    func doesNotThrowWhenPartialSuccess() async throws {
        let songs = (1...25).map { makeSong(id: "s\($0)") }
        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [
            .failure(AppError.unknown),
            .success([])
        ]
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        // Must not throw
        try await sut.executeBatch(songs: songs, onProgress: { _, _ in })
    }

    @Test("Throws the first error when ALL chunks fail")
    func throwsFirstErrorWhenAllChunksFail() async throws {
        let songs = (1...3).map { makeSong(id: "s\($0)") }
        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [.failure(AppError.serverError(statusCode: 500))]
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: MockSongStorageRepository())

        await #expect(throws: AppError.self) {
            try await sut.executeBatch(songs: songs, onProgress: { _, _ in })
        }
    }

    // MARK: Unauthorized short-circuit

    @Test("Throws immediately on unauthorized error, skipping remaining chunks")
    func throwsImmediatelyOnUnauthorized() async throws {
        // 21 songs → 2 chunks; first chunk returns .unauthorized
        let songs = (1...21).map { makeSong(id: "s\($0)") }

        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [
            .failure(AppError.unauthorized),
            .success([])  // should never be reached
        ]
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        await #expect(throws: AppError.self) {
            try await sut.executeBatch(songs: songs, onProgress: { _, _ in })
        }

        #expect(remote.fetchBatchAnalysisCallCount == 1, "Should stop after the unauthorized error")
    }

    // MARK: saveTags integration

    @Test("saveTags is called for every result in a successful chunk")
    func saveTagsCalledForEachResult() async throws {
        let songs = [makeSong(id: "s1"), makeSong(id: "s2")]
        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [
            .success([
                SongAnalysisResult(songId: "s1", tags: [AnalyzedTag(name: "rock", description: nil)]),
                SongAnalysisResult(songId: "s2", tags: [AnalyzedTag(name: "pop", description: nil)])
            ])
        ]
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        try await sut.executeBatch(songs: songs, onProgress: { _, _ in })

        #expect(local.saveTagsCallCount == 2)
        #expect(local.saveTagsReceivedCalls.map(\.songId).sorted() == ["s1", "s2"])
    }

    @Test("saveTags is called with syncStatus .synced")
    func saveTagsUsesSyncedStatus() async throws {
        let songs = [makeSong(id: "s1")]
        let remote = MockSongRepository()
        remote.fetchBatchAnalysisResults = [
            .success([SongAnalysisResult(songId: "s1", tags: [])])
        ]
        let local = MockSongStorageRepository()
        let sut = AnalyzeSongUseCase(remoteRepository: remote, localRepository: local)

        try await sut.executeBatch(songs: songs, onProgress: { _, _ in })

        #expect(local.saveTagsReceivedCalls.first?.syncStatus == .synced)
    }
}

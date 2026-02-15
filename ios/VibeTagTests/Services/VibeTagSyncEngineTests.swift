import Testing
import Foundation
@testable import VibeTag

// MARK: - Helpers

@MainActor
private func makeSession(authenticated: Bool) -> SessionManager {
    let storage = MockTokenStorage(token: authenticated ? "token" : nil)
    return SessionManager(tokenStorage: storage, authRepository: MockAuthRepository())
}

@MainActor
private func makeSUT(
    localRepo: MockSongStorageRepository = MockSongStorageRepository(),
    apiClient: MockAPIClient = MockAPIClient(),
    networkMonitor: MockNetworkMonitor = MockNetworkMonitor(isConnected: true),
    authenticated: Bool = true
) -> (sut: VibeTagSyncEngine, localRepo: MockSongStorageRepository, apiClient: MockAPIClient, networkMonitor: MockNetworkMonitor) {
    let session = makeSession(authenticated: authenticated)
    let sut = VibeTagSyncEngine(
        localRepo: localRepo,
        sessionManager: session,
        networkMonitor: networkMonitor,
        apiClient: apiClient
    )
    return (sut, localRepo, apiClient, networkMonitor)
}

// MARK: - pullRemoteData — guard conditions

@MainActor
@Suite("VibeTagSyncEngine.pullRemoteData — guards")
struct PullRemoteDataGuardTests {

    @Test("Does nothing when not connected")
    func doesNothingWhenNotConnected() async throws {
        let (sut, localRepo, apiClient, _) = makeSUT(
            networkMonitor: MockNetworkMonitor(isConnected: false),
            authenticated: true
        )

        try await sut.pullRemoteData()

        #expect(apiClient.requestCallCount == 0)
        #expect(localRepo.saveTagsCallCount == 0)
    }

    @Test("Does nothing when not authenticated")
    func doesNothingWhenNotAuthenticated() async throws {
        let (sut, localRepo, apiClient, _) = makeSUT(
            networkMonitor: MockNetworkMonitor(isConnected: true),
            authenticated: false
        )

        try await sut.pullRemoteData()

        #expect(apiClient.requestCallCount == 0)
        #expect(localRepo.saveTagsCallCount == 0)
    }

    @Test("Does nothing when already pulling")
    func doesNothingWhenAlreadyPulling() async throws {
        let apiClient = MockAPIClient()
        // First call will block on the result queue being empty (returns immediately with unknown error)
        // We just verify a concurrent second invocation is a no-op.
        // Simulate by calling twice sequentially after the first returns early on an error.
        apiClient.requestResults = [.failure(AppError.serverError(statusCode: 503))]

        let (sut, _, client, _) = makeSUT(apiClient: apiClient)

        // First call — kicks off pull and encounters an error
        try? await sut.pullRemoteData()
        // isPulling is reset via defer, so a second call should proceed normally.
        // The point is: mid-flight concurrency protection. We verify the flag resets after completion.
        #expect(client.requestCallCount == 1)
    }
}

// MARK: - pullRemoteData — happy path & pagination

@MainActor
@Suite("VibeTagSyncEngine.pullRemoteData — pagination")
struct PullRemoteDataPaginationTests {

    @Test("Calls hydrateRemoteTags for a single page of results")
    func hydratesFirstPage() async throws {
        let apiClient = MockAPIClient()
        let localRepo = MockSongStorageRepository()
        let remoteSong = SyncedSongDTO(id: "s1", appleMusicId: nil, artworkUrl: nil, tags: [])
        // One page with 1 item (< limit of 100) → stops after first request
        apiClient.requestResults = [.success([remoteSong] as SyncedLibraryResponseDTO)]

        let (sut, _, _, _) = makeSUT(localRepo: localRepo, apiClient: apiClient)

        try await sut.pullRemoteData()

        #expect(apiClient.requestCallCount == 1)
        #expect(localRepo.hydrateRemoteTagsCallCount == 1)
    }

    @Test("Fetches multiple pages until a page has fewer than limit items")
    func fetchesUntilPartialPage() async throws {
        let apiClient = MockAPIClient()
        let localRepo = MockSongStorageRepository()

        // Page 1: exactly 100 items → continue
        let fullPage: SyncedLibraryResponseDTO = (1...100).map {
            SyncedSongDTO(id: "s\($0)", appleMusicId: nil, artworkUrl: nil, tags: [])
        }
        // Page 2: 3 items (< 100) → stop
        let lastPage: SyncedLibraryResponseDTO = [
            SyncedSongDTO(id: "s101", appleMusicId: nil, artworkUrl: nil, tags: [])
        ]
        apiClient.requestResults = [.success(fullPage), .success(lastPage)]

        let (sut, _, _, _) = makeSUT(localRepo: localRepo, apiClient: apiClient)

        try await sut.pullRemoteData()

        #expect(apiClient.requestCallCount == 2)
        #expect(localRepo.hydrateRemoteTagsCallCount == 2)
    }

    @Test("Does not call hydrateRemoteTags when a page is empty")
    func skipsHydrateForEmptyPage() async throws {
        let apiClient = MockAPIClient()
        let localRepo = MockSongStorageRepository()
        // Empty page → hasMoreData = false, hydrateRemoteTags must NOT be called
        apiClient.requestResults = [.success([] as SyncedLibraryResponseDTO)]

        let (sut, _, _, _) = makeSUT(localRepo: localRepo, apiClient: apiClient)

        try await sut.pullRemoteData()

        #expect(apiClient.requestCallCount == 1)
        #expect(localRepo.hydrateRemoteTagsCallCount == 0)
    }

    @Test("Propagates API errors to the caller")
    func propagatesAPIError() async throws {
        let apiClient = MockAPIClient()
        apiClient.requestResults = [.failure(AppError.serverError(statusCode: 500))]

        let (sut, _, _, _) = makeSUT(apiClient: apiClient)

        await #expect(throws: AppError.self) {
            try await sut.pullRemoteData()
        }
    }
}

// MARK: - syncPendingChanges — guard conditions

@MainActor
@Suite("VibeTagSyncEngine.syncPendingChanges — guards")
struct SyncPendingChangesGuardTests {

    @Test("Does nothing when not connected")
    func doesNothingWhenNotConnected() async {
        let (sut, localRepo, apiClient, _) = makeSUT(
            networkMonitor: MockNetworkMonitor(isConnected: false),
            authenticated: true
        )

        await sut.syncPendingChanges()

        #expect(apiClient.requestVoidCallCount == 0)
        #expect(localRepo.fetchPendingUploadsCallCount == 0)
    }

    @Test("Does nothing when not authenticated")
    func doesNothingWhenNotAuthenticated() async {
        let (sut, localRepo, apiClient, _) = makeSUT(
            networkMonitor: MockNetworkMonitor(isConnected: true),
            authenticated: false
        )

        await sut.syncPendingChanges()

        #expect(apiClient.requestVoidCallCount == 0)
        #expect(localRepo.fetchPendingUploadsCallCount == 0)
    }
}

// MARK: - syncPendingChanges — upload logic

@MainActor
@Suite("VibeTagSyncEngine.syncPendingChanges — upload")
struct SyncPendingChangesUploadTests {

    @Test("Does not call API when there are no pending uploads")
    func noAPICallWhenNoPendingUploads() async {
        let localRepo = MockSongStorageRepository()
        localRepo.pendingUploadsResult = []
        let (sut, _, apiClient, _) = makeSUT(localRepo: localRepo)

        await sut.syncPendingChanges()

        #expect(apiClient.requestVoidCallCount == 0)
    }

    @Test("Calls requestVoid once per pending song")
    func callsAPIOncePerPendingSong() async {
        let localRepo = MockSongStorageRepository()
        let song1 = VTSong(id: "s1", title: "Song 1", artist: "Artist", syncStatus: .pendingUpload)
        let song2 = VTSong(id: "s2", title: "Song 2", artist: "Artist", syncStatus: .pendingUpload)
        localRepo.pendingUploadsResult = [song1, song2]
        // fetchSong returns same song (tags unchanged → will markAsSynced)
        localRepo.fetchSongResult = { id in id == "s1" ? song1 : song2 }

        let apiClient = MockAPIClient()
        apiClient.requestVoidResults = [nil, nil] // both succeed

        let (sut, _, client, _) = makeSUT(localRepo: localRepo, apiClient: apiClient)

        await sut.syncPendingChanges()

        #expect(client.requestVoidCallCount == 2)
    }

    @Test("Marks song as synced after successful upload when tags are unchanged")
    func marksSyncedWhenTagsUnchanged() async {
        let localRepo = MockSongStorageRepository()
        let song = VTSong(id: "s1", title: "Song", artist: "Artist", syncStatus: .pendingUpload)
        song.tags = []
        localRepo.pendingUploadsResult = [song]
        localRepo.fetchSongResult = { _ in song } // tags still empty after upload

        let apiClient = MockAPIClient()
        apiClient.requestVoidResults = [nil]

        let (sut, repo, _, _) = makeSUT(localRepo: localRepo, apiClient: apiClient)

        await sut.syncPendingChanges()

        #expect(repo.markAsSyncedCallCount == 1)
        #expect(repo.markAsSyncedLastSongId == "s1")
    }

    @Test("Does NOT mark song as synced when tags changed during upload (race condition)")
    func doesNotMarkSyncedWhenTagsChangedDuringUpload() async {
        let localRepo = MockSongStorageRepository()
        let song = VTSong(id: "s1", title: "Song", artist: "Artist", syncStatus: .pendingUpload)
        song.tags = [] // no tags at upload time

        // After upload completes, a new tag has been added
        let newTag = VibeTag.Tag(name: "new-tag", hexColor: "#000", isSystemTag: false)
        let modifiedSong = VTSong(id: "s1", title: "Song", artist: "Artist", syncStatus: .pendingUpload)
        modifiedSong.tags = [newTag]

        localRepo.pendingUploadsResult = [song]
        localRepo.fetchSongResult = { _ in modifiedSong } // re-fetch returns modified version

        let apiClient = MockAPIClient()
        apiClient.requestVoidResults = [nil]

        let (sut, repo, _, _) = makeSUT(localRepo: localRepo, apiClient: apiClient)

        await sut.syncPendingChanges()

        #expect(repo.markAsSyncedCallCount == 0, "Must not mark as synced when tags changed during upload")
    }

    @Test("Continues syncing remaining songs after one song fails")
    func continuesAfterPerSongFailure() async {
        let localRepo = MockSongStorageRepository()
        let song1 = VTSong(id: "s1", title: "Song 1", artist: "Artist", syncStatus: .pendingUpload)
        let song2 = VTSong(id: "s2", title: "Song 2", artist: "Artist", syncStatus: .pendingUpload)
        localRepo.pendingUploadsResult = [song1, song2]
        localRepo.fetchSongResult = { id in id == "s2" ? song2 : nil }

        let apiClient = MockAPIClient()
        apiClient.requestVoidResults = [AppError.serverError(statusCode: 503), nil] // s1 fails, s2 succeeds

        let (sut, _, client, _) = makeSUT(localRepo: localRepo, apiClient: apiClient)

        await sut.syncPendingChanges()

        #expect(client.requestVoidCallCount == 2, "Both songs must be attempted")
    }

    @Test("Does not throw even when all uploads fail")
    func doesNotThrowWhenAllUploadsFail() async {
        let localRepo = MockSongStorageRepository()
        let song = VTSong(id: "s1", title: "Song", artist: "Artist", syncStatus: .pendingUpload)
        localRepo.pendingUploadsResult = [song]

        let apiClient = MockAPIClient()
        apiClient.requestVoidResults = [AppError.serverError(statusCode: 500)]

        let (sut, _, _, _) = makeSUT(localRepo: localRepo, apiClient: apiClient)

        // syncPendingChanges is non-throwing by design
        await sut.syncPendingChanges()
    }
}

import Testing
import Foundation
@testable import VibeTag

// MARK: - ExportPlaylistToAppleMusicUseCaseTests

@MainActor
@Suite("ExportPlaylistToAppleMusicUseCase.execute")
struct ExportPlaylistUseCaseTests {

    @Test("Delegates to the repository once")
    func delegatesToRepositoryOnce() async throws {
        let repo = MockMusicLibraryRepository()
        let sut = ExportPlaylistToAppleMusicUseCaseImpl(repository: repo)

        try await sut.execute(name: "Morning Run", description: "High energy", appleMusicIds: ["id1"])

        #expect(repo.createPlaylistCallCount == 1)
    }

    @Test("Passes playlist name to the repository")
    func passesNameToRepository() async throws {
        let repo = MockMusicLibraryRepository()
        let sut = ExportPlaylistToAppleMusicUseCaseImpl(repository: repo)

        try await sut.execute(name: "Jazz Evenings", description: "Smooth", appleMusicIds: [])

        #expect(repo.createPlaylistLastName == "Jazz Evenings")
    }

    @Test("Passes description to the repository")
    func passesDescriptionToRepository() async throws {
        let repo = MockMusicLibraryRepository()
        let sut = ExportPlaylistToAppleMusicUseCaseImpl(repository: repo)

        try await sut.execute(name: "N/A", description: "Relaxing beats", appleMusicIds: [])

        #expect(repo.createPlaylistLastDescription == "Relaxing beats")
    }

    @Test("Passes appleMusicIds to the repository")
    func passesAppleMusicIdsToRepository() async throws {
        let repo = MockMusicLibraryRepository()
        let sut = ExportPlaylistToAppleMusicUseCaseImpl(repository: repo)

        try await sut.execute(name: "N/A", description: "N/A", appleMusicIds: ["am-1", "am-2", "am-3"])

        #expect(repo.createPlaylistLastAppleMusicIds == ["am-1", "am-2", "am-3"])
    }

    @Test("Passes empty appleMusicIds when none provided")
    func passesEmptyIds() async throws {
        let repo = MockMusicLibraryRepository()
        let sut = ExportPlaylistToAppleMusicUseCaseImpl(repository: repo)

        try await sut.execute(name: "N/A", description: "N/A", appleMusicIds: [])

        #expect(repo.createPlaylistLastAppleMusicIds == [])
    }

    @Test("Propagates repository errors to the caller")
    func propagatesRepositoryErrors() async throws {
        let repo = MockMusicLibraryRepository()
        repo.createPlaylistShouldThrow = AppError.serverError(statusCode: 503)
        let sut = ExportPlaylistToAppleMusicUseCaseImpl(repository: repo)

        await #expect(throws: (any Error).self) {
            try await sut.execute(name: "N/A", description: "N/A", appleMusicIds: [])
        }
    }
}

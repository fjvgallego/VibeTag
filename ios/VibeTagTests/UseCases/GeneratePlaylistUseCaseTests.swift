import Testing
import Foundation
@testable import VibeTag

// MARK: - Helpers

private func makeResponse(
    title: String = "Chill Evening",
    songs: [GeneratePlaylistResponseDTO.SongDTO] = []
) -> GeneratePlaylistResponseDTO {
    GeneratePlaylistResponseDTO(playlistTitle: title, description: "desc", usedTags: [], songs: songs)
}

// MARK: - GeneratePlaylistUseCaseTests

@MainActor
@Suite("GeneratePlaylistUseCase.execute")
struct GeneratePlaylistUseCaseTests {

    @Test("Calls the API client once")
    func callsAPIClientOnce() async throws {
        let client = MockAPIClient()
        client.requestResults = [.success(makeResponse())]
        let sut = GeneratePlaylistUseCase(apiClient: client)

        _ = try await sut.execute(prompt: "chill vibes")

        #expect(client.requestCallCount == 1)
    }

    @Test("Returns the response from the API client")
    func returnsResponseFromClient() async throws {
        let client = MockAPIClient()
        client.requestResults = [.success(makeResponse(title: "Morning Run"))]
        let sut = GeneratePlaylistUseCase(apiClient: client)

        let result = try await sut.execute(prompt: "energetic music")

        #expect(result.playlistTitle == "Morning Run")
    }

    @Test("Propagates API client errors to the caller")
    func propagatesErrors() async throws {
        let client = MockAPIClient()
        client.requestResults = [.failure(AppError.serverError(statusCode: 500))]
        let sut = GeneratePlaylistUseCase(apiClient: client)

        await #expect(throws: (any Error).self) {
            _ = try await sut.execute(prompt: "something")
        }
    }

    @Test("Sends a PlaylistEndpoint.generate endpoint")
    func sendsCorrectEndpoint() async throws {
        let client = MockAPIClient()
        client.requestResults = [.success(makeResponse())]
        let sut = GeneratePlaylistUseCase(apiClient: client)

        _ = try await sut.execute(prompt: "study focus")

        #expect(client.requestReceivedEndpoints.count == 1)
    }
}

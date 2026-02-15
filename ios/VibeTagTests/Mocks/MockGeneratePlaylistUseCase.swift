import Foundation
@testable import VibeTag

final class MockGeneratePlaylistUseCase: GeneratePlaylistUseCaseProtocol {
    var executeCallCount = 0
    var executeResult: Result<GeneratePlaylistResponseDTO, Error> = .success(
        GeneratePlaylistResponseDTO(playlistTitle: "Mock Playlist", description: "Mock", usedTags: [], songs: [])
    )

    func execute(prompt: String) async throws -> GeneratePlaylistResponseDTO {
        executeCallCount += 1
        return try executeResult.get()
    }
}

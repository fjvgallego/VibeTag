import Foundation

protocol GeneratePlaylistUseCaseProtocol {
    func execute(prompt: String) async throws -> GeneratePlaylistResponseDTO
}

class GeneratePlaylistUseCase: GeneratePlaylistUseCaseProtocol {
    func execute(prompt: String) async throws -> GeneratePlaylistResponseDTO {
        return try await APIClient.shared.request(PlaylistEndpoint.generate(prompt: prompt))
    }
}

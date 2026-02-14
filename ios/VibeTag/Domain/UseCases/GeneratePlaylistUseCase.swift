import Foundation

protocol GeneratePlaylistUseCaseProtocol {
    func execute(prompt: String) async throws -> GeneratePlaylistResponseDTO
}

class GeneratePlaylistUseCase: GeneratePlaylistUseCaseProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func execute(prompt: String) async throws -> GeneratePlaylistResponseDTO {
        return try await apiClient.request(PlaylistEndpoint.generate(prompt: prompt))
    }
}

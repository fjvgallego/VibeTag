import Foundation

struct AppleLoginRequest: Encodable {
    let identityToken: String
    let firstName: String?
    let lastName: String?
}

class VibeTagAuthRepository: AuthRepository {
    
    init() {}
    
    func login(identityToken: String, firstName: String?, lastName: String?) async throws -> AuthResponse {
        let requestBody = AppleLoginRequest(
            identityToken: identityToken,
            firstName: firstName,
            lastName: lastName
        )
        
        do {
            let dto: AuthResponseDTO = try await APIClient.shared.request(AuthEndpoint.login(request: requestBody))
            return dto.toDomain()
        } catch let error as APIError {
            throw error.toAppError
        } catch {
            throw AppError.networkError(original: error)
        }
    }
    
    func deleteAccount() async throws {
        do {
            try await APIClient.shared.requestVoid(AuthEndpoint.deleteAccount)
        } catch let error as APIError {
            throw error.toAppError
        } catch {
            throw AppError.networkError(original: error)
        }
    }
}

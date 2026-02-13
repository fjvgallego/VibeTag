import Foundation
@testable import VibeTag

final class MockAuthRepository: AuthRepository {
    func login(identityToken: String, firstName: String?, lastName: String?) async throws -> AuthResponse {
        AuthResponse(token: "mock-token", user: User(id: "u1", email: nil, firstName: nil, lastName: nil))
    }
    func deleteAccount() async throws {}
}

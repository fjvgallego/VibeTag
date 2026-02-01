import Foundation

protocol AuthRepository {
    func login(identityToken: String, firstName: String?, lastName: String?) async throws -> AuthResponse
    func deleteAccount() async throws
}

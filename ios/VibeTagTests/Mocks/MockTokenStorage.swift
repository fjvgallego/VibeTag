import Foundation
@testable import VibeTag

final class MockTokenStorage: TokenStorage {
    private var token: String?

    init(token: String? = nil) {
        self.token = token
    }

    func save(token: String) throws { self.token = token }
    func getToken() -> String? { token }
    func deleteToken() throws { token = nil }
}

import Foundation
import SwiftUI

@MainActor
@Observable
class SessionManager {
    var isAuthenticated: Bool = false
    var userEmail: String? = nil
    
    private let tokenStorage: TokenStorage
    private let authRepository: AuthRepository
    
    init(tokenStorage: TokenStorage, authRepository: AuthRepository) {
        self.tokenStorage = tokenStorage
        self.authRepository = authRepository
        self.isAuthenticated = tokenStorage.getToken() != nil
        // For now, let's just use a dummy email if authenticated
        if isAuthenticated {
            self.userEmail = "usuario@vibetag.app"
        }
    }
    
    func logout() {
        do {
            try tokenStorage.deleteToken()
        } catch {
            print("Logout failed: \(error)")
        }
        isAuthenticated = false
    }
    
    func deleteAccount() async throws {
        do {
            try await authRepository.deleteAccount()
            self.logout()
        } catch {
            print("Delete account failed: \(error)")
            throw error
        }
    }
    
    func login(token: String) throws {
        do {
            try tokenStorage.save(token: token)
            isAuthenticated = true
        } catch {
            print("Saving token failed: \(error)")
            throw error
        }
    }
}

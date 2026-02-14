import Foundation
import SwiftUI

@MainActor
@Observable
class SessionManager {
    var isAuthenticated: Bool = false
    var userEmail: String? = nil
    
    var onAccountDeleted: (() -> Void)?
    var onLogout: (() -> Void)?
    
    private let tokenStorage: TokenStorage
    private let authRepository: AuthRepository
    
    init(tokenStorage: TokenStorage, authRepository: AuthRepository, onAccountDeleted: (() -> Void)? = nil, onLogout: (() -> Void)? = nil) {
        self.tokenStorage = tokenStorage
        self.authRepository = authRepository
        self.onAccountDeleted = onAccountDeleted
        self.onLogout = onLogout
        self.isAuthenticated = tokenStorage.getToken() != nil
        // For now, let's just use a dummy email if authenticated
        if isAuthenticated {
            self.userEmail = "usuario@vibetag.app"
        }
    }
    
    func logout() {
        do {
            try tokenStorage.deleteToken()
            self.onLogout?()
        } catch {
            print("Logout failed: \(error)")
        }
        isAuthenticated = false
    }
    
    func deleteAccount() async throws {
        do {
            try await authRepository.deleteAccount()
            self.onAccountDeleted?()
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

import Foundation
import SwiftUI

@Observable
class SessionManager {
    var isAuthenticated: Bool = false
    
    private let tokenStorage: TokenStorage
    private let authRepository: AuthRepository
    
    init(tokenStorage: TokenStorage = KeychainTokenStorage(), authRepository: AuthRepository = VibeTagAuthRepository()) {
        self.tokenStorage = tokenStorage
        self.authRepository = authRepository
        self.isAuthenticated = tokenStorage.getToken() != nil
    }
    
    func logout() {
        do {
            try tokenStorage.deleteToken()
            isAuthenticated = false
        } catch {
            print("Logout failed: \(error)")
        }
    }
    
    func deleteAccount() async {
        do {
            try await authRepository.deleteAccount()
            await MainActor.run {
                self.logout()
            }
        } catch {
            print("Delete account failed: \(error)")
            // Optionally handle error (e.g. show alert)
        }
    }
    
    func login(token: String) {
        do {
            try tokenStorage.save(token: token)
            isAuthenticated = true
        } catch {
            print("Saving token failed: \(error)")
        }
    }
}

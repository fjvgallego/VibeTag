import Foundation
import SwiftUI

@Observable
class SessionManager {
    var isAuthenticated: Bool = false
    
    private let tokenStorage: TokenStorage
    
    init(tokenStorage: TokenStorage = KeychainTokenStorage()) {
        self.tokenStorage = tokenStorage
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
    
    func login(token: String) {
        do {
            try tokenStorage.save(token: token)
            isAuthenticated = true
        } catch {
            print("Saving token failed: \(error)")
        }
    }
}

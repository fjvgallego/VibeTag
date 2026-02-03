import SwiftUI
import AuthenticationServices

@MainActor
@Observable
class LoginViewModel: NSObject {
    var errorMessage: String?
    var isAuthenticated: Bool = false
    var sessionManager: SessionManager?
    var syncEngine: SyncEngine?
    
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository,
         sessionManager: SessionManager? = nil,
         syncEngine: SyncEngine? = nil) {
        self.authRepository = authRepository
        self.sessionManager = sessionManager
        self.syncEngine = syncEngine
    }
    
    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
                self.errorMessage = "Failed to process Apple Sign In credentials"
                return
            }
            
            let firstName = appleIDCredential.fullName?.givenName
            let lastName = appleIDCredential.fullName?.familyName
            
            Task {
                do {
                    let response = try await authRepository.login(
                        identityToken: identityTokenString,
                        firstName: firstName,
                        lastName: lastName
                    )
                    
                    if let sessionManager = sessionManager {
                        try sessionManager.login(token: response.token)
                        self.isAuthenticated = sessionManager.isAuthenticated
                    } else {
                        // Fallback if sessionManager is not provided (e.g. tests)
                        try KeychainTokenStorage().save(token: response.token)
                        self.isAuthenticated = true
                    }
                    
                    // Trigger remote data pull after login
                    await syncEngine?.pullRemoteData()
                } catch {
                    self.errorMessage = error.localizedDescription
                    print("Login Error: \(error)")
                }
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
            print("Sign in failed: \(error.localizedDescription)")
        }
    }
}

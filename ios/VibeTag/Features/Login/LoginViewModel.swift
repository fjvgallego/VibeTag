import SwiftUI
import AuthenticationServices

@MainActor
@Observable
class LoginViewModel: NSObject {
    var errorMessage: String?
    var isAuthenticated: Bool = false
    
    private let authRepository: AuthRepository
    private let tokenStorage: TokenStorage
    
    init(authRepository: AuthRepository = VibeTagAuthRepository(),
         tokenStorage: TokenStorage = KeychainTokenStorage()) {
        self.authRepository = authRepository
        self.tokenStorage = tokenStorage
    }
    
    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
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
                    
                    try tokenStorage.save(token: response.token)
                    
                    self.isAuthenticated = true
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

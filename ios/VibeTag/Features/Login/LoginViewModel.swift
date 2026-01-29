import SwiftUI
import AuthenticationServices

@MainActor
@Observable
class LoginViewModel: NSObject {
    var errorMessage: String?
    var isAuthenticated: Bool = false
    
    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                // User ID: appleIDCredential.user
                // Identity Token: appleIDCredential.identityToken
                // Authorization Code: appleIDCredential.authorizationCode
                // Name: appleIDCredential.fullName
                // Email: appleIDCredential.email
                
                if let identityTokenData = appleIDCredential.identityToken,
                   let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                    
                    // TODO: Call the backend
                    // loginWithBackend(token: identityTokenString)
                    
                    isAuthenticated = true
                }
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
            print("Sign in failed: \(error.localizedDescription)")
        }
    }
}

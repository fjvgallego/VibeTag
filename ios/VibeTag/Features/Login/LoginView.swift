import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var viewModel = LoginViewModel(authRepository: VibeTagAuthRepositoryImpl())
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionManager.self) var sessionManager
    @Environment(VibeTagSyncEngine.self) var syncEngine
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 20)
            
            Text("Welcome to VibeTag")
                .font(.nunito(.largeTitle, weight: .bold))
            
            Text("Sign in to sync your vibes across devices.")
                .font(.nunito(.body))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
                .frame(height: 50)
            
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                viewModel.handleAuthorization(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .frame(maxWidth: 300)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.nunito(.caption))
            }
        }
        .padding()
        .onAppear {
            viewModel.sessionManager = sessionManager
            viewModel.syncEngine = syncEngine
            // Trigger Local Network permission prompt early
            APIClient.shared.ping()
        }
        .onChange(of: viewModel.isAuthenticated) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(SessionManager(tokenStorage: KeychainTokenStorage(), authRepository: VibeTagAuthRepositoryImpl()))
}

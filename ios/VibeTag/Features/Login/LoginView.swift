import AuthenticationServices
import SwiftData
import SwiftUI

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
            .disabled(viewModel.isSyncing)
            .opacity(viewModel.isSyncing ? 0.5 : 1.0)
            
            if viewModel.isSyncing {
                HStack {
                    ProgressView()
                        .padding(.trailing, 8)
                    Text("Syncing your library...")
                        .font(.nunito(.subheadline))
                        .foregroundStyle(.secondary)
                }
            }
            
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
        }
        .onChange(of: viewModel.isAuthenticated) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

#Preview {
    let modelContainer = try! ModelContainer(
        for: VTSong.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let modelContext = modelContainer.mainContext
    let sessionManager = SessionManager(tokenStorage: KeychainTokenStorage(), authRepository: VibeTagAuthRepositoryImpl())
    let localRepo = LocalSongStorageRepositoryImpl(modelContext: modelContext)
    let syncEngine = VibeTagSyncEngine(localRepo: localRepo, sessionManager: sessionManager)
    
    return LoginView()
        .environment(sessionManager)
        .environment(syncEngine)
        .modelContainer(modelContainer)
}

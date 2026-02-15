import SwiftUI
import SwiftData
import AuthenticationServices

struct WelcomeView: View {
    let container: AppContainer
    @State private var animateBackground = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    logoSection

                    VStack(spacing: 8) {
                        Text("VibeTag")
                            .font(.nunito(.largeTitle, weight: .heavy))
                            .foregroundColor(.primary)

                        Text("Tus vibes, tus playlists")
                            .font(.nunito(.title3, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAuthorization(result: result)
                    }
                    .signInWithAppleButtonStyle(Color.primary == .white ? .white : .black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .safeAreaPadding()
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = "No se pudieron procesar las credenciales de Apple."
                return
            }

            let firstName = credential.fullName?.givenName
            let lastName = credential.fullName?.familyName

            Task {
                do {
                    let response = try await container.authRepo.login(
                        identityToken: identityToken,
                        firstName: firstName,
                        lastName: lastName
                    )
                    try container.sessionManager.login(token: response.token)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private var logoSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white)
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)

            Image(systemName: "music.quarternote.3")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appleMusicRed, .appleMusicRed.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var backgroundView: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            RadialGradient(
                stops: [
                    .init(color: .appleMusicRed.opacity(0.1), location: 0),
                    .init(color: .clear, location: 0.7)
                ],
                center: animateBackground ? .topLeading : .bottomTrailing,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animateBackground)

            RadialGradient(
                stops: [
                    .init(color: Color(red: 0.9, green: 0.9, blue: 1.0).opacity(0.3), location: 0),
                    .init(color: .clear, location: 0.6)
                ],
                center: animateBackground ? .bottomTrailing : .topLeading,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateBackground)
        }
        .onAppear {
            animateBackground = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try! ModelContainer(for: VTSong.self, Tag.self, configurations: config)
    let appContainer = AppContainer(modelContext: modelContainer.mainContext)
    WelcomeView(container: appContainer)
}

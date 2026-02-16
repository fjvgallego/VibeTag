import Foundation
import Observation
import MusicKit
import AuthenticationServices

@MainActor
@Observable
class SettingsViewModel {

    // MARK: - UI-only State

    var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined

    var isAppleMusicLinked: Bool {
        musicAuthorizationStatus == .authorized
    }

    // MARK: - Pass-throughs from LibraryActionService

    var isSyncing: Bool { libraryActionService.isSyncing }
    var isAnalyzing: Bool { libraryActionService.isAnalyzing }
    var analysisProgress: Double { libraryActionService.analysisProgress }
    var analysisStatus: String { libraryActionService.analysisStatus }
    var errorMessage: String? {
        get { libraryActionService.errorMessage }
        set { libraryActionService.errorMessage = newValue }
    }

    // MARK: - Dependencies

    private let libraryActionService: LibraryActionServiceProtocol
    private let authRepository: AuthRepository

    init(
        libraryActionService: LibraryActionServiceProtocol,
        authRepository: AuthRepository = VibeTagAuthRepositoryImpl()
    ) {
        self.libraryActionService = libraryActionService
        self.authRepository = authRepository
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
    }

    // MARK: - Actions

    func updateAuthorizationStatus() {
        musicAuthorizationStatus = MusicAuthorization.currentStatus
    }

    func requestMusicPermissions() {
        Task {
            let status = await MusicAuthorization.request()
            await MainActor.run {
                self.musicAuthorizationStatus = status
            }
        }
    }

    func handleAuthorization(result: Result<ASAuthorization, Error>, sessionManager: SessionManager) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
                libraryActionService.errorMessage = "No se pudieron procesar las credenciales de Apple"
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
                    try sessionManager.login(token: response.token)

                    // Pull remote data after login
                    do {
                        try await libraryActionService.pullRemoteData()
                    } catch {
                        print("Initial sync failed: \(error.localizedDescription)")
                    }
                } catch {
                    libraryActionService.errorMessage = error.localizedDescription
                    print("Login Error: \(error)")
                }
            }

        case .failure(let error):
            libraryActionService.errorMessage = error.localizedDescription
            print("Sign in failed: \(error.localizedDescription)")
        }
    }

    func performFullSync() async {
        await libraryActionService.performFullSync()
    }

    func analyzeLibrary() async {
        await libraryActionService.analyzeLibrary()
    }

    func cancelAnalysis() {
        libraryActionService.cancelAnalysis()
    }
}

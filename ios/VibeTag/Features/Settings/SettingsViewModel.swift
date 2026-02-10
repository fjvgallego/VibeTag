import Foundation
import Observation
import SwiftData
import MusicKit
import AuthenticationServices

@Observable
class SettingsViewModel {
    var isSyncing = false
    var isAnalyzing = false
    var analysisProgress: Double = 0
    var analysisStatus: String = ""
    var errorMessage: String? = nil
    
    var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined
    
    var isAppleMusicLinked: Bool {
        musicAuthorizationStatus == .authorized
    }
    
    private let analyzeUseCase: AnalyzeSongUseCase
    private let localRepository: SongStorageRepository
    private let authRepository: AuthRepository
    
    init(analyzeUseCase: AnalyzeSongUseCase, localRepository: SongStorageRepository, authRepository: AuthRepository = VibeTagAuthRepositoryImpl()) {
        self.analyzeUseCase = analyzeUseCase
        self.localRepository = localRepository
        self.authRepository = authRepository
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
    }
    
    func updateAuthorizationStatus() {
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
    }
    
    func requestMusicPermissions() {
        Task {
            let status = await MusicAuthorization.request()
            await MainActor.run {
                self.musicAuthorizationStatus = status
            }
        }
    }
    
    @MainActor
    func handleAuthorization(result: Result<ASAuthorization, Error>, sessionManager: SessionManager, syncEngine: VibeTagSyncEngine) {
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
                    
                    try sessionManager.login(token: response.token)
                    
                    // Trigger remote data pull after login
                    self.isSyncing = true
                    do {
                        try await syncEngine.pullRemoteData()
                    } catch {
                        print("Initial sync failed: \(error.localizedDescription)")
                    }
                    self.isSyncing = false
                    
                } catch {
                    self.errorMessage = error.localizedDescription
                    self.isSyncing = false
                    print("Login Error: \(error)")
                }
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
            print("Sign in failed: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func performFullSync(modelContext: ModelContext, syncEngine: VibeTagSyncEngine) async {
        isSyncing = true
        errorMessage = nil

        do {
            // 1. Sync local library with Apple Music
            let service = AppleMusicLibraryImportService(modelContext: modelContext)
            try await service.syncLibrary()

            // 2. Pull remote data
            try await syncEngine.pullRemoteData()
        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }

        isSyncing = false
    }
    
    @MainActor
    func analyzeLibrary() async {
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0
        analysisStatus = "Iniciando análisis..."
        
        do {
            let songs = try localRepository.fetchAllSongs()
            let songsToAnalyze = songs.filter { $0.tags.isEmpty }
            
            if songsToAnalyze.isEmpty {
                analysisStatus = "La biblioteca ya está analizada"
                isAnalyzing = false
                return
            }
            
            try await analyzeUseCase.executeBatch(songs: songsToAnalyze) { current, total in
                self.analysisProgress = Double(current) / Double(total)
                self.analysisStatus = "Analizando \(current)/\(total)..."
            }
            
            let remaining = try localRepository.fetchAllSongs().filter { $0.tags.isEmpty }.count
            if remaining > 0 {
                analysisStatus = "Análisis finalizado con \(remaining) canciones omitidas."
            } else {
                analysisStatus = "¡Análisis completo!"
            }
        } catch {
            errorMessage = "Error en el análisis: \(error.localizedDescription)"
        }
        
        isAnalyzing = false
    }
}

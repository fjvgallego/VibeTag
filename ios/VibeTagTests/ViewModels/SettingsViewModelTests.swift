import Testing
import Foundation
import MusicKit
@testable import VibeTag

// MARK: - Helpers

@MainActor private func makeSUT(
    libraryActionService: MockLibraryActionService = MockLibraryActionService(),
    authRepository: MockAuthRepository = MockAuthRepository()
) -> (sut: SettingsViewModel, service: MockLibraryActionService) {
    let sut = SettingsViewModel(
        libraryActionService: libraryActionService,
        authRepository: authRepository
    )
    return (sut, libraryActionService)
}

@MainActor private func makeSessionManager() -> SessionManager {
    SessionManager(
        tokenStorage: MockTokenStorage(),
        authRepository: MockAuthRepository()
    )
}

// MARK: - Pass-through state

@MainActor
@Suite("SettingsViewModel — pass-through state")
struct SettingsViewModelPassThroughTests {

    @Test("isSyncing reflects the service")
    func isSyncingPassThrough() {
        let service = MockLibraryActionService()
        let (sut, _) = makeSUT(libraryActionService: service)
        service.isSyncing = true
        #expect(sut.isSyncing == true)
    }

    @Test("isAnalyzing reflects the service")
    func isAnalyzingPassThrough() {
        let service = MockLibraryActionService()
        let (sut, _) = makeSUT(libraryActionService: service)
        service.isAnalyzing = true
        #expect(sut.isAnalyzing == true)
    }

    @Test("analysisProgress reflects the service")
    func analysisProgressPassThrough() {
        let service = MockLibraryActionService()
        let (sut, _) = makeSUT(libraryActionService: service)
        service.analysisProgress = 0.75
        #expect(sut.analysisProgress == 0.75)
    }

    @Test("errorMessage get reflects the service")
    func errorMessageGetPassThrough() {
        let service = MockLibraryActionService()
        let (sut, _) = makeSUT(libraryActionService: service)
        service.errorMessage = "boom"
        #expect(sut.errorMessage == "boom")
    }

    @Test("errorMessage set propagates to the service")
    func errorMessageSetPassThrough() {
        let service = MockLibraryActionService()
        let (sut, _) = makeSUT(libraryActionService: service)
        sut.errorMessage = "oops"
        #expect(service.errorMessage == "oops")
    }

    @Test("isAppleMusicLinked is false when status is notDetermined")
    func isAppleMusicLinkedFalseWhenNotDetermined() {
        let (sut, _) = makeSUT()
        sut.musicAuthorizationStatus = .notDetermined
        #expect(sut.isAppleMusicLinked == false)
    }

    @Test("isAppleMusicLinked is true when status is authorized")
    func isAppleMusicLinkedTrueWhenAuthorized() {
        let (sut, _) = makeSUT()
        sut.musicAuthorizationStatus = .authorized
        #expect(sut.isAppleMusicLinked == true)
    }
}

// MARK: - Action delegation

@MainActor
@Suite("SettingsViewModel — action delegation")
struct SettingsViewModelActionTests {

    @Test("performFullSync delegates to the service")
    func performFullSyncDelegates() async {
        let (sut, service) = makeSUT()
        await sut.performFullSync()
        #expect(service.performFullSyncCallCount == 1)
    }

    @Test("analyzeLibrary delegates to the service")
    func analyzeLibraryDelegates() async {
        let (sut, service) = makeSUT()
        await sut.analyzeLibrary()
        #expect(service.analyzeLibraryCallCount == 1)
    }
}

// MARK: - handleAuthorization

@MainActor
@Suite("SettingsViewModel.handleAuthorization")
struct SettingsViewModelHandleAuthorizationTests {

    @Test("Sets errorMessage on authorization failure")
    func setsErrorOnFailure() async {
        let (sut, service) = makeSUT()
        let sessionManager = makeSessionManager()
        let error = AppError.unknown

        sut.handleAuthorization(result: .failure(error), sessionManager: sessionManager)
        // Give the inner Task a chance to run (none in failure path — it's synchronous)
        #expect(service.errorMessage != nil)
    }

    @Test("Does not authenticate sessionManager on authorization failure")
    func doesNotAuthenticateOnFailure() async {
        let (sut, _) = makeSUT()
        let sessionManager = makeSessionManager()

        sut.handleAuthorization(result: .failure(AppError.unknown), sessionManager: sessionManager)

        #expect(sessionManager.isAuthenticated == false)
    }
}

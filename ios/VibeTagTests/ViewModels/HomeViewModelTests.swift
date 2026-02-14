import Testing
import Foundation
@testable import VibeTag
internal import MusicKit

// MARK: - Helpers

@MainActor
private func makeSUT(
    service: MockLibraryActionService = MockLibraryActionService()
) -> (sut: HomeViewModel, service: MockLibraryActionService) {
    let sut = HomeViewModel(libraryActionService: service)
    return (sut, service)
}

// MARK: - Computed properties

@MainActor
@Suite("HomeViewModel — computed properties")
struct HomeViewModelComputedPropertyTests {

    @Test("isAppleMusicLinked is true when status is authorized")
    func isLinkedWhenAuthorized() {
        let (sut, _) = makeSUT()
        sut.musicAuthorizationStatus = .authorized
        #expect(sut.isAppleMusicLinked == true)
    }

    @Test("isAppleMusicLinked is false when status is not authorized")
    func isNotLinkedWhenNotAuthorized() {
        let (sut, _) = makeSUT()
        sut.musicAuthorizationStatus = .notDetermined
        #expect(sut.isAppleMusicLinked == false)
    }

    @Test("analysisProgress reflects service value")
    func progressReflectsService() {
        let service = MockLibraryActionService()
        service.analysisProgress = 0.6
        let (sut, _) = makeSUT(service: service)
        #expect(sut.analysisProgress == 0.6)
    }
}

// MARK: - State pass-throughs

@MainActor
@Suite("HomeViewModel — service state pass-throughs")
struct HomeViewModelPassThroughTests {

    @Test("isSyncing reflects service state")
    func isSyncingPassThrough() {
        let service = MockLibraryActionService()
        service.isSyncing = true
        let (sut, _) = makeSUT(service: service)
        #expect(sut.isSyncing == true)
    }

    @Test("isAnalyzing reflects service state")
    func isAnalyzingPassThrough() {
        let service = MockLibraryActionService()
        service.isAnalyzing = true
        let (sut, _) = makeSUT(service: service)
        #expect(sut.isAnalyzing == true)
    }

    @Test("totalSongsCount reflects service state")
    func totalSongsCountPassThrough() {
        let service = MockLibraryActionService()
        service.totalSongsCount = 42
        let (sut, _) = makeSUT(service: service)
        #expect(sut.totalSongsCount == 42)
    }

    @Test("unanalyzedCount reflects service state")
    func unanalyzedCountPassThrough() {
        let service = MockLibraryActionService()
        service.unanalyzedCount = 7
        let (sut, _) = makeSUT(service: service)
        #expect(sut.unanalyzedCount == 7)
    }

    @Test("errorMessage get reads from service")
    func errorMessageGetPassThrough() {
        let service = MockLibraryActionService()
        service.errorMessage = "boom"
        let (sut, _) = makeSUT(service: service)
        #expect(sut.errorMessage == "boom")
    }

    @Test("errorMessage set writes to service")
    func errorMessageSetPassThrough() {
        let service = MockLibraryActionService()
        let (sut, _) = makeSUT(service: service)
        sut.errorMessage = "test error"
        #expect(service.errorMessage == "test error")
    }
}

// MARK: - Action delegation

@MainActor
@Suite("HomeViewModel — action delegation")
struct HomeViewModelActionDelegationTests {

    @Test("syncLibrary delegates to library action service")
    func syncLibraryDelegates() async {
        let (sut, service) = makeSUT()
        await sut.syncLibrary()
        #expect(service.syncLibraryCallCount == 1)
    }

    @Test("performFullSync delegates to library action service")
    func performFullSyncDelegates() async {
        let (sut, service) = makeSUT()
        await sut.performFullSync()
        #expect(service.performFullSyncCallCount == 1)
    }

    @Test("analyzeLibrary delegates to library action service")
    func analyzeLibraryDelegates() async {
        let (sut, service) = makeSUT()
        await sut.analyzeLibrary()
        #expect(service.analyzeLibraryCallCount == 1)
    }

    @Test("refreshLibraryStats delegates to library action service")
    func refreshLibraryStatsDelegates() {
        let (sut, service) = makeSUT()
        sut.refreshLibraryStats()
        #expect(service.refreshLibraryStatsCallCount == 1)
    }

    @Test("updateAuthorizationStatus calls refreshLibraryStats on service")
    func updateAuthorizationStatusRefreshesStats() {
        let (sut, service) = makeSUT()
        sut.updateAuthorizationStatus()
        #expect(service.refreshLibraryStatsCallCount == 1)
    }
}

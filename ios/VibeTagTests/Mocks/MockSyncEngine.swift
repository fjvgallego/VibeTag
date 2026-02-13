import Foundation
@testable import VibeTag

@MainActor
final class MockSyncEngine: SyncEngine {
    var syncPendingChangesCallCount = 0
    var pullRemoteDataCallCount = 0
    var pullRemoteDataShouldThrow: Error?

    func syncPendingChanges() async {
        syncPendingChangesCallCount += 1
    }

    func pullRemoteData() async throws {
        pullRemoteDataCallCount += 1
        if let error = pullRemoteDataShouldThrow { throw error }
    }
}

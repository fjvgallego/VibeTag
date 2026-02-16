import Foundation

@MainActor
protocol SyncEngine {
    func syncPendingChanges() async
    func pullRemoteData() async throws
}
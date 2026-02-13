import Foundation
@testable import VibeTag

final class MockLibraryImportSyncService: LibraryImportSyncService {
    var syncLibraryCallCount = 0
    var syncLibraryShouldThrow: Error?

    func syncLibrary() async throws {
        syncLibraryCallCount += 1
        if let error = syncLibraryShouldThrow { throw error }
    }
}

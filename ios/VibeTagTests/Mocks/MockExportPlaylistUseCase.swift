import Foundation
@testable import VibeTag

final class MockExportPlaylistUseCase: ExportPlaylistToAppleMusicUseCase {
    var executeCallCount = 0
    var executeLastName: String?
    var executeLastDescription: String?
    var executeLastAppleMusicIds: [String]?
    var executeShouldThrow: Error?

    func execute(name: String, description: String, appleMusicIds: [String]) async throws {
        executeCallCount += 1
        executeLastName = name
        executeLastDescription = description
        executeLastAppleMusicIds = appleMusicIds
        if let error = executeShouldThrow { throw error }
    }
}

import Foundation
@testable import VibeTag

@MainActor
final class MockAnalyzeSongUseCase: AnalyzeSongUseCaseProtocol {

    // MARK: - execute (single)

    var executeResult: Result<[AnalyzedTag], Error> = .success([])
    var executeCallCount = 0

    func execute(song: VTSong) async throws -> [AnalyzedTag] {
        executeCallCount += 1
        return try executeResult.get()
    }

    // MARK: - executeBatch

    var executeBatchShouldThrow: Error?
    /// Each tuple is a (current, total) pair fired to onProgress, in order.
    var executeBatchProgressSimulation: [(Int, Int)] = []
    /// When true, suspends between progress steps so cancellation can be observed.
    var executeBatchSuspendsIndefinitely: Bool = false

    func executeBatch(songs: [VTSong], onProgress: @escaping (Int, Int) -> Void) async throws {
        if let error = executeBatchShouldThrow { throw error }
        for (current, total) in executeBatchProgressSimulation {
            try Task.checkCancellation()
            onProgress(current, total)
        }
        if executeBatchSuspendsIndefinitely {
            try await Task.sleep(for: .seconds(60))
        }
    }
}

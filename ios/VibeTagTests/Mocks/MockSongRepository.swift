import Foundation
@testable import VibeTag

@MainActor
final class MockSongRepository: SongRepository {

    // MARK: - fetchAnalysis

    var fetchAnalysisCallCount = 0
    var fetchAnalysisLastSong: VTSong?
    var fetchAnalysisResult: Result<[AnalyzedTag], Error> = .success([])

    func fetchAnalysis(for song: VTSong) async throws -> [AnalyzedTag] {
        fetchAnalysisCallCount += 1
        fetchAnalysisLastSong = song
        return try fetchAnalysisResult.get()
    }

    // MARK: - fetchBatchAnalysis

    var fetchBatchAnalysisCallCount = 0
    var fetchBatchAnalysisLastSongs: [VTSong] = []
    /// Each element in the array is the result for one call (consumed in order).
    var fetchBatchAnalysisResults: [Result<[SongAnalysisResult], Error>] = []

    func fetchBatchAnalysis(for songs: [VTSong]) async throws -> [SongAnalysisResult] {
        fetchBatchAnalysisCallCount += 1
        fetchBatchAnalysisLastSongs = songs
        guard !fetchBatchAnalysisResults.isEmpty else { return [] }
        return try fetchBatchAnalysisResults.removeFirst().get()
    }

    // MARK: - Unused in AnalyzeSongUseCase tests

    func searchSongs(query: String) async throws -> [VTSong] { [] }
    func fetchSongs(limit: Int) async throws -> [VTSong] { [] }
}

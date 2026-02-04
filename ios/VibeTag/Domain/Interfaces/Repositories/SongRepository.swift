import Foundation

@MainActor
protocol SongRepository {
    func searchSongs(query: String) async throws -> [VTSong]
    func fetchSongs(limit: Int) async throws -> [VTSong]
    func fetchAnalysis(for song: VTSong) async throws -> [TagDTO]
    func fetchBatchAnalysis(dto: BatchAnalyzeRequestDTO) async throws -> BatchAnalyzeResponseDTO
}

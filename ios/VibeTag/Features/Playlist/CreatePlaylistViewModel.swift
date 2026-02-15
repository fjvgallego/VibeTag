import Foundation
import Observation
import UIKit

@MainActor
@Observable
class CreatePlaylistViewModel {
    var prompt: String = ""
    var isLoading: Bool = false
    var isExporting: Bool = false
    var isExported: Bool = false
    var errorMessage: String? = nil

    // MARK: - Derived state

    var hasResult: Bool { result != nil }

    var songs: [VTSong] {
        result?.songs.map { dto in
            let song = VTSong(id: dto.id, appleMusicId: dto.appleMusicId, title: dto.title, artist: dto.artist, artworkUrl: dto.artworkUrl)
            song.tags = dto.tags.map { VibeTag.Tag(name: $0.name, hexColor: "#FF2D55", isSystemTag: $0.type == "SYSTEM") }
            return song
        } ?? []
    }

    // MARK: - Private

    var result: GeneratePlaylistResponseDTO?
    private let generatePlaylistUseCase: GeneratePlaylistUseCaseProtocol
    private let exportPlaylistUseCase: ExportPlaylistToAppleMusicUseCase

    init(generatePlaylistUseCase: GeneratePlaylistUseCaseProtocol, exportPlaylistUseCase: ExportPlaylistToAppleMusicUseCase) {
        self.generatePlaylistUseCase = generatePlaylistUseCase
        self.exportPlaylistUseCase = exportPlaylistUseCase
    }

    // MARK: - Actions

    func generatePlaylist() async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        result = nil
        isLoading = true
        errorMessage = nil

        do {
            result = try await generatePlaylistUseCase.execute(prompt: prompt)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func exportPlaylist() async {
        guard let result, !isExporting, !isExported else { return }

        isExporting = true
        errorMessage = nil

        let appleMusicIds = result.songs.compactMap { $0.appleMusicId }

        do {
            try await exportPlaylistUseCase.execute(
                name: result.playlistTitle,
                description: result.description,
                appleMusicIds: appleMusicIds
            )
            isExported = true
            isExporting = false
        } catch {
            errorMessage = "Failed to export playlist: \(error.localizedDescription)"
            isExporting = false
        }
    }
}

import Foundation
import Observation
import UIKit

@Observable
class CreatePlaylistViewModel {
    var prompt: String = ""
    var isLoading: Bool = false
    var isExporting: Bool = false
    var isExported: Bool = false
    var result: GeneratePlaylistResponseDTO? = nil
    var errorMessage: String? = nil
    
    private let generatePlaylistUseCase: GeneratePlaylistUseCase
    private let exportPlaylistUseCase: ExportPlaylistToAppleMusicUseCase
    
    init(generatePlaylistUseCase: GeneratePlaylistUseCase, exportPlaylistUseCase: ExportPlaylistToAppleMusicUseCase) {
        self.generatePlaylistUseCase = generatePlaylistUseCase
        self.exportPlaylistUseCase = exportPlaylistUseCase
    }
    
    @MainActor
    func generatePlaylist() async {
        guard !prompt.isEmpty else { return }
        
        result = nil
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await generatePlaylistUseCase.execute(prompt: prompt)
            self.result = response
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    @MainActor
    func exportPlaylist() async {
        guard let result = result, !isExporting, !isExported else { return }
        
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
            
            // Open Apple Music app
            if let musicURL = URL(string: "music://") {
                if await UIApplication.shared.canOpenURL(musicURL) {
                    await UIApplication.shared.open(musicURL)
                }
            }
        } catch {
            self.errorMessage = "Failed to export playlist: \(error.localizedDescription)"
            isExporting = false
        }
    }
}

import Foundation
import Observation

@Observable
class CreatePlaylistViewModel {
    var prompt: String = ""
    var isLoading: Bool = false
    var result: GeneratePlaylistResponseDTO? = nil
    var errorMessage: String? = nil
    
    private let generatePlaylistUseCase: GeneratePlaylistUseCase
    
    init(generatePlaylistUseCase: GeneratePlaylistUseCase) {
        self.generatePlaylistUseCase = generatePlaylistUseCase
    }
    
    @MainActor
    func generatePlaylist() async {
        guard !prompt.isEmpty, result == nil else { return }
        
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
}

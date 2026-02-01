import Foundation
import Observation

@Observable
class SongDetailViewModel {
    var song: VTSong
    var isAnalyzing: Bool = false
    var analysisTags: [String] = []
    
    private let useCase: AnalyzeSongUseCaseProtocol
    
    init(song: VTSong, useCase: AnalyzeSongUseCaseProtocol) {
        self.song = song
        self.useCase = useCase
        self.analysisTags = song.tags.map { $0.name }
        
        if analysisTags.isEmpty {
            analyzeSong()
        }
    }
    
    @MainActor
    func analyzeSong() {
        isAnalyzing = true
        
        Task {
            do {
                let tags = try await useCase.execute(song: song)
                self.analysisTags = tags
            } catch {
                print("Error analyzing song: \(error)")
            }
            self.isAnalyzing = false
        }
    }
}

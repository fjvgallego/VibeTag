import Foundation
import Observation

@Observable
class SongDetailViewModel {
    var song: VTSong
    var isAnalyzing: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    
    private let useCase: AnalyzeSongUseCaseProtocol
    private let repository: SongStorageRepository
    private let syncEngine: SyncEngine
    
    init(song: VTSong, 
         useCase: AnalyzeSongUseCaseProtocol, 
         repository: SongStorageRepository,
         syncEngine: SyncEngine) {
        self.song = song
        self.useCase = useCase
        self.repository = repository
        self.syncEngine = syncEngine
        
        if song.tags.isEmpty {
            analyzeSong()
        }
    }
    
    @MainActor
    func analyzeSong() {
        isAnalyzing = true
        
        Task {
            do {
                let tags = try await useCase.execute(song: song)
                
                // If tags were automatically added, sync them
                if !tags.isEmpty {
                    await syncEngine.syncPendingChanges()
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
            self.isAnalyzing = false
        }
    }

    @MainActor
    func addTag(_ tagName: String) {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check for duplicates
        if song.tags.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            return
        }
        
        let previousTags = song.tags
        var currentTagNames = song.tags.map { $0.name }
        currentTagNames.append(trimmedName)
        
        // Optimistic update
        let newTag = Tag(name: trimmedName, hexColor: "#808080") // Default color for optimistic UI
        song.tags.append(newTag)
        
        Task {
            do {
                try await repository.saveTags(for: song.id, tags: currentTagNames)
                await syncEngine.syncPendingChanges()
            } catch {
                await MainActor.run {
                    self.song.tags = previousTags // Revert on failure
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    @MainActor
    func removeTag(_ tagName: String) {
        guard let index = song.tags.firstIndex(where: { 
            $0.name.caseInsensitiveCompare(tagName) == .orderedSame 
        }) else { return }
        
        var currentTagNames = song.tags.map { $0.name }
        currentTagNames.remove(at: index)
        
        let updatedTags = song.tags.filter { $0.name.caseInsensitiveCompare(tagName) != .orderedSame }
        
        Task {
            do {
                try await repository.saveTags(for: song.id, tags: currentTagNames)
                await syncEngine.syncPendingChanges()
                
                await MainActor.run {
                    self.song.tags = updatedTags
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
}

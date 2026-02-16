import Foundation
import Observation

@Observable
class SongDetailViewModel {
    var song: VTSong
    var isAnalyzing: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    
    var systemTags: [Tag] {
        song.tags.filter { $0.isSystemTag }.sorted(by: { $0.name < $1.name })
    }
    
    var userTags: [Tag] {
        song.tags.filter { !$0.isSystemTag }.sorted(by: { $0.name < $1.name })
    }
    
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
    func addTag(_ tagName: String, description: String? = nil) {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDesc = (trimmedDesc?.isEmpty ?? true) ? nil : trimmedDesc
        
        guard !trimmedName.isEmpty else { return }
        
        // Check for duplicates
        if song.tags.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            return
        }
        
        let previousTags = song.tags
        var currentTags = song.tags.map { AnalyzedTag(name: $0.name, description: $0.tagDescription) }
        currentTags.append(AnalyzedTag(name: trimmedName, description: finalDesc))
        
        // Optimistic update: Check if tag exists globally first
        let existingTag = try? repository.fetchTag(name: trimmedName)
        let newTag = existingTag ?? Tag(name: trimmedName, tagDescription: finalDesc, hexColor: "#808080")
        song.tags.append(newTag)
        
        Task {
            do {
                try await repository.saveTags(for: song.id, tags: currentTags)
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
        
        var currentTags = song.tags.map { AnalyzedTag(name: $0.name, description: $0.tagDescription) }
        currentTags.remove(at: index)
        
        let updatedTags = song.tags.filter { $0.name.caseInsensitiveCompare(tagName) != .orderedSame }
        
        Task {
            do {
                try await repository.saveTags(for: song.id, tags: currentTags)
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

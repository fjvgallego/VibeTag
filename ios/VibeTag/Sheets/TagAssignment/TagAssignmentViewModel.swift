import Foundation
import Observation
import SwiftData

@MainActor
@Observable
class TagAssignmentViewModel {

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let syncEngine: any SyncEngine

    init(modelContext: ModelContext, syncEngine: any SyncEngine) {
        self.modelContext = modelContext
        self.syncEngine = syncEngine
    }

    // MARK: - Actions

    func toggleTag(_ tag: VibeTag.Tag, on song: VTSong) {
        if let index = song.tags.firstIndex(of: tag) {
            song.tags.remove(at: index)
        } else {
            song.tags.append(tag)
        }
        song.syncStatus = .pendingUpload
        do {
            try modelContext.save()
            Task { await syncEngine.syncPendingChanges() }
        } catch {
            print("Failed to save tag assignment: \(error)")
        }
    }

    func createAndToggleTag(name: String, hexColor: String, description: String?, on song: VTSong) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<VibeTag.Tag>(predicate: #Predicate { $0.name == trimmedName })
        let existingTags = try? modelContext.fetch(descriptor)
        if let existingTag = existingTags?.first {
            toggleTag(existingTag, on: song)
            return
        }
        let newTag = VibeTag.Tag(name: trimmedName, tagDescription: description, hexColor: hexColor)
        modelContext.insert(newTag)
        toggleTag(newTag, on: song)
    }
}

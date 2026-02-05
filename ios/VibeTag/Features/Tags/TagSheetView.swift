import SwiftUI
import SwiftData

struct TagSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(VibeTagSyncEngine.self) private var syncEngine
    
    @Bindable var song: VTSong
    
    @Query(sort: \Tag.name) private var tags: [Tag]
    
    @State private var errorMessage: String?
    @State private var newTagName: String = ""
    @State private var isCreatingTag: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(tags) { tag in
                        Button {
                            toggleTag(tag)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(hex: tag.hexColor) ?? .gray)
                                    .frame(width: 12, height: 12)
                                
                                Text(tag.name)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if song.tags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteTags)
                } header: {
                    Text("Available Tags")
                }
                
                Section {
                    if isCreatingTag {
                        HStack {
                            TextField("Tag Name", text: $newTagName)
                                .onSubmit {
                                    createNewTag()
                                }
                            
                            Button("Add") {
                                createNewTag()
                            }
                            .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button("Create New Tag") {
                            withAnimation {
                                isCreatingTag = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if let index = song.tags.firstIndex(of: tag) {
            song.tags.remove(at: index)
        } else {
            song.tags.append(tag)
        }
        
        triggerSync()
    }
    
    private func createNewTag() {
        let cleanName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
        // Check for duplicate names (case insensitive)
        if tags.contains(where: { $0.name.localizedCaseInsensitiveCompare(cleanName) == .orderedSame }) {
            // If duplicate exists, just clear input for now
            newTagName = ""
            isCreatingTag = false
            return
        }
        
        let newTag = Tag(name: cleanName, hexColor: "#808080") // Default gray
        modelContext.insert(newTag)
        song.tags.append(newTag)
        
        newTagName = ""
        isCreatingTag = false
        
        triggerSync()
    }

    private func triggerSync() {
        song.syncStatus = .pendingUpload
        
        do {
            try modelContext.save()
            Task {
                await syncEngine.syncPendingChanges()
            }
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
    
    private func deleteTags(at offsets: IndexSet) {
        var deletedTags: [Tag] = []
        
        for index in offsets {
            let tagToDelete = tags[index]
            deletedTags.append(tagToDelete)
            
            // Remove from current song if present
            if let songTagIndex = song.tags.firstIndex(of: tagToDelete) {
                song.tags.remove(at: songTagIndex)
            }
            
            modelContext.delete(tagToDelete)
        }
        
        // Find ALL songs that contained any of the deleted tags
        // This is necessary because deleting a tag leaves those songs with stale remote states
        do {
            let allSongs = try modelContext.fetch(FetchDescriptor<VTSong>())
            for affectedSong in allSongs {
                if deletedTags.contains(where: { affectedSong.tags.contains($0) }) {
                    affectedSong.syncStatus = .pendingUpload
                }
            }
            
            // Current song is already marked for sync via its own relationship removal if it had the tag,
            // but we ensure it's pending if it was affected by this operation.
            song.syncStatus = .pendingUpload
            
            try modelContext.save()
            
            Task {
                await syncEngine.syncPendingChanges()
            }
        } catch {
            errorMessage = "Failed to process tag deletion: \(error.localizedDescription)"
        }
    }
}

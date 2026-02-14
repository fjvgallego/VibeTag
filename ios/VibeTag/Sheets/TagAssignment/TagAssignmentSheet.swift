import SwiftUI
import SwiftData

struct TagAssignmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(VibeTagSyncEngine.self) private var syncEngine

    @Bindable var song: VTSong

    @Query(filter: #Predicate<VibeTag.Tag> { tag in
        tag.isSystemTag == false
    }, sort: \VibeTag.Tag.name) private var allTags: [VibeTag.Tag]

    @State private var showingCreateTag = false
    @State private var viewModel: TagAssignmentViewModel?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Etiquetar Canción")
                    .font(.nunito(.title2, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 40)

                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: song.artworkUrl ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else {
                            Color.gray.opacity(0.2)
                        }
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Text("\(song.title) - \(song.artist)")
                        .font(.nunito(.caption, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 32)

            // Tag Cloud
            ScrollView {
                VStack {
                    TagFlowLayout(spacing: 10) {
                        ForEach(allTags) { tag in
                            TagToggleCapsule(
                                tag: tag,
                                isSelected: song.tags.contains(tag)
                            ) {
                                viewModel?.toggleTag(tag, on: song)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 100)
            }

            Spacer()

            // Footer Action
            Button {
                showingCreateTag = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Nueva Etiqueta")
                }
                .font(.nunito(.callout, weight: .semibold))
                .foregroundColor(.appleMusicRed)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().stroke(Color.appleMusicRed, lineWidth: 1))
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .onAppear {
            viewModel = TagAssignmentViewModel(modelContext: modelContext, syncEngine: syncEngine)
        }
        .sheet(isPresented: $showingCreateTag) {
            CreateTagSheet { name, hexColor, description in
                viewModel?.createAndToggleTag(name: name, hexColor: hexColor, description: description, on: song)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Components

private struct TagToggleCapsule: View {
    let tag: VibeTag.Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag.name)
                .font(.nunito(.body, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? (Color(hex: tag.hexColor) ?? .appleMusicRed) : Color(.systemGray6).opacity(0.5))
                )
                .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try! ModelContainer(for: VTSong.self, VibeTag.Tag.self, configurations: config)
    let appContainer = AppContainer(modelContext: modelContainer.mainContext)
    let song = VTSong(id: "1", title: "Midnight City", artist: "M83")
    return TagAssignmentSheet(song: song)
        .modelContainer(modelContainer)
        .environment(appContainer.syncEngine)
}

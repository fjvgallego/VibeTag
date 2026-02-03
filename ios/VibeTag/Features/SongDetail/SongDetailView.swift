import SwiftUI

struct SongDetailView: View {
    @State private var viewModel: SongDetailViewModel
    @State private var showingAddTagAlert = false
    @State private var newTagName = ""
    
    init(song: VTSong, container: AppContainer, syncEngine: SyncEngine) {
        let viewModel = SongDetailViewModel(
            song: song,
            useCase: container.analyzeSongUseCase,
            repository: container.localRepo,
            syncEngine: syncEngine
        )
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Artwork
                if let artworkUrl = viewModel.song.artworkUrl, let url = URL(string: artworkUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.song.title)
                        .font(.title)
                        .bold()
                    
                    Text(viewModel.song.artist)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Tags Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Tags ✨")
                            .font(.title3)
                            .bold()
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddTagAlert = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    if viewModel.isAnalyzing {
                        HStack {
                            ProgressView()
                            Text("Analyzing Tags...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else if !viewModel.song.tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.song.tags) { tag in
                                Text(tag.name)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                                    )
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.removeTag(tag.name)
                                        } label: {
                                            Label("Remove Tag", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    } else {
                        Button(action: {
                            viewModel.analyzeSong()
                        }) {
                            Label("Analyze Tags ✨", systemImage: "sparkles")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Song Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Add Tag", isPresented: $showingAddTagAlert) {
            TextField("Tag name", text: $newTagName)
                .textInputAutocapitalization(.never)
            Button("Add") {
                viewModel.addTag(newTagName.trimmingCharacters(in: .whitespacesAndNewlines))
                newTagName = ""
            }
            .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {
                newTagName = ""
            }
        } message: {
            Text("Enter a name for this tag.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// Simple FlowLayout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let proposalWidth = proposal.replacingUnspecifiedDimensions().width
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > proposalWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        return CGSize(width: proposalWidth, height: currentY + lineHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
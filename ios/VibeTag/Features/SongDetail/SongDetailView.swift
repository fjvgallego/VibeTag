import SwiftUI
import SwiftData

struct SongDetailView: View {
    @State private var viewModel: SongDetailViewModel
    @State private var showingEditTags = false
    @Environment(\.dismiss) private var dismiss
    
    init(song: VTSong, container: AppContainer, syncEngine: VibeTagSyncEngine) {
        self._viewModel = State(initialValue: SongDetailViewModel(
            song: song,
            useCase: container.analyzeSongUseCase,
            repository: container.localRepo,
            syncEngine: syncEngine
        ))
    }
    
    var body: some View {
        ZStack {
            // Background Atmosphere
            backgroundLayer
                .ignoresSafeArea()
            
            // Dark Overlay - Ensures full screen coverage
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        Spacer().frame(height: 60)
                        
                        // Header (Artwork)
                        artworkSection
                        
                        // Metadata
                        metadataSection
                        
                        // Sections
                        VStack(alignment: .leading, spacing: 32) {
                            systemTagsSection
                            userTagsSection
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 60)
                    }
                    .frame(maxWidth: .infinity)
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(false)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingEditTags) {
            TagAssignmentSheet(song: viewModel.song)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var backgroundLayer: some View {
        ZStack {
            Color.black
            
            GeometryReader { geometry in
                AsyncImage(url: URL(string: viewModel.song.artworkUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    default:
                        Color.clear
                    }
                }
                .blur(radius: 60)
            }
        }
    }
    
    private var artworkSection: some View {
        AsyncImage(url: URL(string: viewModel.song.artworkUrl ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                placeholderArtwork
            }
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
    
    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.1))
            .frame(width: 280, height: 280)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.2))
            }
    }
    
    private var metadataSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.song.title)
                .font(.nunito(.title, weight: .heavy))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text(viewModel.song.artist)
                .font(.nunito(.title3, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private var systemTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.white.opacity(0.6))
                Text("ETIQUETAS DEL SISTEMA")
                    .font(.nunito(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .kerning(1.2)
            }
            
            if viewModel.isAnalyzing {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Analizando vibras...")
                        .font(.nunito(.subheadline, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 8)
            } else if viewModel.systemTags.isEmpty {
                Button(action: { viewModel.analyzeSong() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "wand.and.stars")
                        Text("Analizar Canción")
                    }
                    .font(.nunito(.subheadline, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.appleMusicRed)
                    .clipShape(Capsule())
                }
            } else {
                TagFlowLayout(spacing: 12, alignment: .leading) {
                    ForEach(viewModel.systemTags) { tag in
                        DetailTagCapsule(tag: tag)
                    }
                }
            }
        }
    }
    
    private var userTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.6))
                    Text("MIS ETIQUETAS")
                        .font(.nunito(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .kerning(1.2)
                }
                
                Spacer()
                
                if !viewModel.userTags.isEmpty {
                    Button(action: { showingEditTags = true }) {
                        Text("Editar")
                            .font(.nunito(.caption, weight: .bold))
                            .foregroundColor(.appleMusicRed)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.appleMusicRed.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            
            if viewModel.userTags.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Añade tu toque personal...")
                        .font(.nunito(.caption, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.leading, 4)
                    
                    Button(action: { showingEditTags = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Añadir Etiqueta")
                        }
                        .font(.nunito(.subheadline, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                    }
                }
            } else {
                TagFlowLayout(spacing: 12, alignment: .leading) {
                    ForEach(viewModel.userTags) { tag in
                        DetailTagCapsule(tag: tag)
                    }
                }
            }
        }
    }
}

private struct DetailTagCapsule: View {
    let tag: Tag
    @State private var showingPopover = false
    
    private var tagColor: Color {
        Color(hex: tag.hexColor) ?? .white
    }
    
    private var backgroundColor: Color {
        tagColor.opacity(0.2)
    }
    
    private var strokeColor: Color {
        tagColor.opacity(0.4)
    }
    
    var body: some View {
        Text(tag.name.uppercased())
            .font(.nunito(.callout, weight: .black))
            .lineLimit(1)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(tag.isSystemTag ? .white : tagColor)
            .background(
                Capsule()
                    .fill(
                        tag.isSystemTag ? 
                        AnyShapeStyle(LinearGradient(colors: [.purple, .indigo, .blue], startPoint: .leading, endPoint: .trailing)) :
                        AnyShapeStyle(backgroundColor)
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(tag.isSystemTag ? .white.opacity(0.3) : strokeColor, lineWidth: 1)
            )
            .frame(maxWidth: 250)
            .onTapGesture {
                showingPopover = true
            }
            .popover(isPresented: $showingPopover) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(tag.name)
                        .font(.nunito(.headline, weight: .bold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let description = tag.tagDescription, !description.isEmpty {
                        Text(description)
                            .font(.nunito(.subheadline, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .frame(minWidth: 150, maxWidth: 300)
                .presentationCompactAdaptation(.popover)
            }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: VTSong.self, Tag.self, configurations: config)
    
    let song = VTSong(
        id: "1",
        title: "Starboy",
        artist: "The Weeknd",
        artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/08/43/d8/0843d83c-684a-6fbc-979d-02cfc7FB4401/16UMGIM56450.rgb.jpg/600x600bb.jpg"
    )
    
    let tag1 = Tag(name: "Electronic", hexColor: "#5856D6")
    let tag2 = Tag(name: "Vibey", hexColor: "#FF2D55")
    song.tags = [tag1, tag2]
    
    let appContainer = AppContainer(modelContext: container.mainContext)
    let syncEngine = VibeTagSyncEngine(localRepo: appContainer.localRepo, sessionManager: SessionManager(tokenStorage: appContainer.tokenStorage, authRepository: appContainer.authRepo))
    
    return NavigationStack {
        SongDetailView(song: song, container: appContainer, syncEngine: syncEngine)
    }
    .modelContainer(container)
}

import SwiftUI

struct CreatePlaylistView: View {
    @State private var viewModel: CreatePlaylistViewModel
    @Environment(\.dismiss) private var dismiss
    let prompt: String
    
    init(generatePlaylistUseCase: GeneratePlaylistUseCase, prompt: String) {
        self.prompt = prompt
        self._viewModel = State(initialValue: CreatePlaylistViewModel(generatePlaylistUseCase: generatePlaylistUseCase))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background: Using adaptive background color
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                promptHeader
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                ZStack {
                    if viewModel.isLoading {
                        loadingState
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else if let response = viewModel.result {
                        resultState(response: response)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else if viewModel.errorMessage != nil {
                        errorState
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.isLoading)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.isLoading && viewModel.errorMessage == nil {
                ToolbarItem(placement: .principal) {
                    headerLabel
                }
            }
        }
        .onAppear {
            viewModel.prompt = prompt
            Task {
                await viewModel.generatePlaylist()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var promptHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appleMusicRed)
            
            Text(prompt)
                .font(.nunito(.body, weight: .medium))
                .foregroundColor(.primary.opacity(0.8))
                .italic()
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(16)
        .glassEffect()
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }
    
    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Creando tu vibe...")
                .font(.nunito(.title2, weight: .bold))
                .foregroundColor(.primary)
                .shimmering()
            
            Image(systemName: "sparkles")
                .font(.system(size: 30))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("appleMusicRed"), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func resultState(response: GeneratePlaylistResponseDTO) -> some View {
        let vtSongs = response.songs.map { dto in
            let song = VTSong(id: dto.id, title: dto.title, artist: dto.artist)
            song.tags = dto.tags.map { Tag(name: $0, hexColor: "#FF2D55") }
            return song
        }
        
        return ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(vtSongs) { song in
                            SongRowView(song: song)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            
            PrimaryActionButton("Exportar a Apple Music", icon: "apple.logo") {
                print("Exporting...")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    private var errorState: some View {
        ContentUnavailableView {
            Label("Error al generar", systemImage: "exclamationmark.triangle")
        } description: {
            Text(viewModel.errorMessage ?? "Ocurrió un error inesperado")
        } actions: {
            PrimaryActionButton("Reintentar", icon: "arrow.clockwise") {
                Task { await viewModel.generatePlaylist() }
            }
            .padding(.horizontal, 40)
        }
    }
    
    private var headerLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 10))
            Text("Análisis de IA completo")
                .font(.nunito(.caption, weight: .medium))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.05))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

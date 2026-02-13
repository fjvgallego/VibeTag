import SwiftUI

struct CreatePlaylistView: View {
    @State private var viewModel: CreatePlaylistViewModel
    @State private var isEditingPrompt = false
    @Environment(\.dismiss) private var dismiss
    let prompt: String
    
    init(generatePlaylistUseCase: GeneratePlaylistUseCase, exportPlaylistUseCase: ExportPlaylistToAppleMusicUseCase, prompt: String) {
        self.prompt = prompt
        self._viewModel = State(initialValue: CreatePlaylistViewModel(
            generatePlaylistUseCase: generatePlaylistUseCase,
            exportPlaylistUseCase: exportPlaylistUseCase
        ))
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
                        if response.songs.isEmpty {
                            noResultsState
                                .transition(.opacity)
                        } else {
                            resultState(response: response)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
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
        .sheet(isPresented: $isEditingPrompt) {
            VibeInputSheet(initialText: viewModel.prompt) { newPrompt in
                isEditingPrompt = false
                viewModel.prompt = newPrompt
                Task {
                    await viewModel.generatePlaylist()
                }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            if viewModel.prompt.isEmpty {
                viewModel.prompt = prompt
            }
            if viewModel.result == nil && !viewModel.isLoading {
                Task {
                    await viewModel.generatePlaylist()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var promptHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appleMusicRed)
            
            Text(viewModel.prompt)
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
            let song = VTSong(id: dto.id, appleMusicId: dto.appleMusicId, title: dto.title, artist: dto.artist, artworkUrl: dto.artworkUrl)
            song.tags = dto.tags.map { Tag(name: $0.name, hexColor: "#FF2D55", isSystemTag: $0.type == "SYSTEM") }
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
                    .padding(.bottom, 150)
                }
            }
            
            VStack(spacing: 12) {
                if viewModel.isExported {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text("¡Playlist guardada en Apple Music!")
                                .font(.nunito(.headline, weight: .bold))
                        }
                        .padding(.top, 8)
                        
                        HStack(spacing: 12) {
                            Button(action: { dismiss() }) {
                                Text("Hecho")
                                    .font(.nunito(.headline, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.primary.opacity(0.05))
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: {
                                if let musicURL = URL(string: "music://") {
                                    UIApplication.shared.open(musicURL)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "apple.logo")
                                    Text("Abrir Music")
                                }
                                .font(.nunito(.headline, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    PrimaryActionButton(
                        viewModel.isExporting ? "Exportando..." : "Exportar a Apple Music",
                        icon: "apple.logo"
                    ) {
                        Task {
                            await viewModel.exportPlaylist()
                        }
                    }
                    .disabled(viewModel.isExporting)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    private var noResultsState: some View {
        ContentUnavailableView {
            Label("No encontramos canciones", systemImage: "music.note.list")
        } description: {
            Text("¡No te rindas! Intenta describir tus sentimientos con más detalle. Cuanto más específico seas (menciona géneros, estados de ánimo o momentos), mejor podrá la IA encontrar tu vibe.")
        } actions: {
            PrimaryActionButton("Reintentar y editar", icon: "pencil") {
                isEditingPrompt = true
            }
            .padding(.horizontal, 40)
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

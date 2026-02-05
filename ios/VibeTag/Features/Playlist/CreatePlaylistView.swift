import SwiftUI

struct CreatePlaylistView: View {
    @State private var viewModel: CreatePlaylistViewModel
    
    init(generatePlaylistUseCase: GeneratePlaylistUseCase) {
        self._viewModel = State(initialValue: CreatePlaylistViewModel(generatePlaylistUseCase: generatePlaylistUseCase))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe your vibe")
                        .font(.headline)
                    
                    TextField("e.g., Chill lofi beats for studying", text: $viewModel.prompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                    
                    Button {
                        Task {
                            await viewModel.generatePlaylist()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("✨ Generate Magic Playlist")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.prompt.isEmpty || viewModel.isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.prompt.isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Result Section
                if let result = viewModel.result {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(result.playlistTitle)
                            .font(.title2)
                            .bold()
                        
                        Text(result.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Tags
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(result.usedTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Text("Songs (\(result.songs.count))")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(result.songs) { song in
                                VStack(alignment: .leading) {
                                    Text(song.title)
                                        .font(.body)
                                        .lineLimit(1)
                                    Text(song.artist)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                if song.id != result.songs.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding()
                } else if !viewModel.isLoading {
                    ContentUnavailableView("Your playlist will appear here", systemImage: "sparkles")
                        .padding(.top, 40)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Magic Playlist")
        .navigationBarTitleDisplayMode(.inline)
    }
}

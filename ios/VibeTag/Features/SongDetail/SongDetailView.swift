import SwiftUI

struct SongDetailView: View {
    var viewModel: SongDetailViewModel
    
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
                
                // Vibe Tags Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Vibe Tags ✨")
                        .font(.title3)
                        .bold()
                    
                    if viewModel.isAnalyzing {
                        HStack {
                            ProgressView()
                            Text("Reading Vibes...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else if !viewModel.analysisTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.analysisTags, id: \.self) { tag in
                                    Text(tag)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    } else {
                        Button(action: {
                            viewModel.analyzeSong()
                        }) {
                            Label("Analyze Vibe ✨", systemImage: "sparkles")
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
    }
}

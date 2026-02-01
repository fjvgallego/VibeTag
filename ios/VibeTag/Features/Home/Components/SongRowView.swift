import SwiftUI

struct SongRowView: View {
    let song: VTSong
    @State private var showTagsSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: song.artworkUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.3)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Color.gray.opacity(0.3)
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundStyle(.gray)
                        }
                @unknown default:
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.nunito(.headline, weight: .semibold))
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.nunito(.subheadline))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                showTagsSheet = true
            } label: {
                Label("Manage Tags", systemImage: "tag")
            }
        }
        .swipeActions(edge: .trailing) {
            Button {
                showTagsSheet = true
            } label: {
                Label("Tags", systemImage: "tag")
            }
            .tint(.blue)
        }
        .sheet(isPresented: $showTagsSheet) {
            TagSheetView(song: song)
        }
    }
}

#Preview {
    let previewSong = VTSong(
        id: "1",
        title: "Preview Song",
        artist: "Preview Artist",
        artworkUrl: "https://example.com/art.jpg"
    )
    return SongRowView(song: previewSong)
}
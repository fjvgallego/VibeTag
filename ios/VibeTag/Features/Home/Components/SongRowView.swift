import SwiftUI

struct SongRowView: View {
    let song: VTSong
    
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
                    .font(.headline)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .contentShape(Rectangle())
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
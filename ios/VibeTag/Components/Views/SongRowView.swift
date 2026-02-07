import SwiftUI

struct SongRowView: View {
    let song: VTSong
    @State private var showTagsSheet = false
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        HStack(spacing: 16) {
            // Artwork
            AsyncImage(url: URL(string: song.artworkUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    placeholderView
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.nunito(.headline, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.nunito(.subheadline, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Tags
                if !song.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(song.tags.prefix(3).sorted(by: { $0.name < $1.name })) { tag in
                            TagCapsule(tag: tag)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            router.navigate(to: .songDetail(songID: song.id))
        }
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
            .tint(Color("appleMusicRed"))
        }
        .sheet(isPresented: $showTagsSheet) {
            TagAssignmentSheet(song: song)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var placeholderView: some View {
        Color.gray.opacity(0.1)
            .overlay {
                Image(systemName: "music.note")
                    .foregroundStyle(.gray.opacity(0.5))
            }
    }
}

private struct TagCapsule: View {
    let tag: Tag
    
    var body: some View {
        Text(tag.name.uppercased())
            .font(.nunito(size: 10, weight: .black))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(hex: tag.hexColor)?.opacity(0.1) ?? Color.gray.opacity(0.1))
            )
            .foregroundColor(Color(hex: tag.hexColor) ?? .primary)
    }
}

#Preview {
    let previewSong = VTSong(
        id: "1",
        title: "Midnight City",
        artist: "M83",
        artworkUrl: "https://example.com/art.jpg"
    )
    let tag1 = Tag(name: "Dreamy", hexColor: "#FF2D55")
    let tag2 = Tag(name: "Synth", hexColor: "#5856D6")
    previewSong.tags = [tag1, tag2]
    
    return SongRowView(song: previewSong)
        .environment(AppRouter())
}

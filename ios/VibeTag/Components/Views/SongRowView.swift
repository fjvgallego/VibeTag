import SwiftUI

struct SongRowView: View {
    let song: VTSong
    @State private var showTagsSheet = false
    @State private var dragOffset: CGFloat = 0
    @State private var hasTriggeredHaptic = false
    @Environment(AppRouter.self) private var router
    
    private let threshold: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Reveal Layer (Behind the card)
            HStack {
                Image(systemName: "tag.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.blue)
                    .scaleEffect(dragOffset > threshold ? 1.2 : 0.8)
                    .opacity(dragOffset > 20 ? 1 : 0)
                    .animation(.spring(response: 0.3), value: dragOffset > threshold)
                Spacer()
            }
            .padding(.leading, 32)
            
            // Main Content Card
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
                        TagFlowView(tags: song.tags.sorted(by: { $0.name < $1.name }))
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .offset(x: dragOffset)
            .contentShape(Rectangle())
            .onTapGesture {
                router.navigate(to: .songDetail(songID: song.id))
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        // Only allow leading-to-trailing swipe
                        if value.translation.width > 0 {
                            dragOffset = value.translation.width
                            
                            // Haptic feedback threshold
                            if dragOffset > threshold && !hasTriggeredHaptic {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                hasTriggeredHaptic = true
                            } else if dragOffset <= threshold {
                                hasTriggeredHaptic = false
                            }
                        }
                    }
                    .onEnded { value in
                        if dragOffset > threshold {
                            showTagsSheet = true
                        }
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                        hasTriggeredHaptic = false
                    }
            )
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showTagsSheet = true
            } label: {
                Label("Tags", systemImage: "tag.fill")
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

private struct TagFlowView: View {
    let tags: [Tag]
    @State private var visibleTagCount: Int = 0
    @State private var showOverflow: Bool = false
    
    var body: some View {
        TagFlowLayout(spacing: 6, maxRows: 2) {
            ForEach(tags.prefix(visibleTagCount)) { tag in
                TagCapsule(tag: tag)
            }

            if showOverflow {
                let remaining = max(0, tags.count - visibleTagCount)
                if remaining > 0 {
                    Text("+\(remaining)")
                        .font(.nunito(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .foregroundColor(.secondary)
                }
            }
        }
        .background {
            GeometryReader { geometry in
                Color.clear.onAppear {
                    calculateVisibleTags(width: geometry.size.width)
                }
                .onChange(of: geometry.size.width) { _, newWidth in
                    calculateVisibleTags(width: newWidth)
                }
            }
        }
    }
    
    private static let measureFont: UIFont = UIFont(name: "Nunito-Bold", size: 10) ?? .systemFont(ofSize: 10, weight: .bold)

    private func measureTagWidth(_ name: String) -> CGFloat {
        let text = name.uppercased() as NSString
        let size = text.size(withAttributes: [.font: Self.measureFont])
        return ceil(size.width) + 20 // .padding(.horizontal, 10) on each side
    }

    private func measureBadgeWidth(_ count: Int) -> CGFloat {
        let text = "+\(count)" as NSString
        let size = text.size(withAttributes: [.font: Self.measureFont])
        return ceil(size.width) + 16 // .padding(.horizontal, 8) on each side
    }

    private func calculateVisibleTags(width: CGFloat) {
        var currentWidth: CGFloat = 0
        var currentRow: Int = 1
        var count = 0
        let spacing: CGFloat = 6

        var rowStartCount = 0

        for tag in tags {
            let tagWidth = measureTagWidth(tag.name)

            if currentWidth + tagWidth > width {
                currentRow += 1
                rowStartCount = count
                currentWidth = tagWidth + spacing
            } else {
                currentWidth += tagWidth + spacing
            }

            if currentRow > 2 {
                var fitCount = count
                var fitWidth = currentWidth - tagWidth - spacing
                let remaining = tags.count - fitCount
                let badgeWidth = measureBadgeWidth(remaining)

                while fitCount > rowStartCount && fitWidth + badgeWidth + spacing > width {
                    fitCount -= 1
                    let removedWidth = measureTagWidth(tags[fitCount].name) + spacing
                    fitWidth -= removedWidth
                }

                showOverflow = true
                visibleTagCount = fitCount
                return
            }

            count += 1
        }

        showOverflow = false
        visibleTagCount = tags.count
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

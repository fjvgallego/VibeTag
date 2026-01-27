import SwiftUI
import SwiftData

struct SongListView: View {
    @Query private var songs: [VTSong]
    
    init(searchTokens: [String]) {
        let predicate: Predicate<VTSong>
        
        // Filter out empty tokens and take max 3 to avoid excessive complexity
        let tokens = searchTokens.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.prefix(3).map { $0 }
        
        if tokens.isEmpty {
            predicate = #Predicate<VTSong> { _ in true }
        } else if tokens.count == 1 {
            let t0 = tokens[0]
            predicate = #Predicate<VTSong> { song in
                song.title.localizedStandardContains(t0) ||
                song.artist.localizedStandardContains(t0) ||
                song.tags.contains { $0.name.localizedStandardContains(t0) }
            }
        } else if tokens.count == 2 {
            let t0 = tokens[0]
            let t1 = tokens[1]
            predicate = #Predicate<VTSong> { song in
                (song.title.localizedStandardContains(t0) || song.title.localizedStandardContains(t1)) ||
                (song.artist.localizedStandardContains(t0) || song.artist.localizedStandardContains(t1)) ||
                song.tags.contains { tag in
                    tag.name.localizedStandardContains(t0) || tag.name.localizedStandardContains(t1)
                }
            }
        } else {
            // Max 3 tokens
            let t0 = tokens[0]
            let t1 = tokens[1]
            let t2 = tokens[2]
            predicate = #Predicate<VTSong> { song in
                (song.title.localizedStandardContains(t0) || song.title.localizedStandardContains(t1) || song.title.localizedStandardContains(t2)) ||
                (song.artist.localizedStandardContains(t0) || song.artist.localizedStandardContains(t1) || song.artist.localizedStandardContains(t2)) ||
                song.tags.contains { tag in
                    tag.name.localizedStandardContains(t0) || tag.name.localizedStandardContains(t1) || tag.name.localizedStandardContains(t2)
                }
            }
        }
        
        _songs = Query(filter: predicate, sort: \.dateAdded, order: .reverse)
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(songs) { song in
                SongRowView(song: song)
            }
        }
    }
}

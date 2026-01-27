import SwiftUI
import SwiftData

struct SongListView: View {
    @Query(sort: \VTSong.dateAdded, order: .reverse) private var allSongs: [VTSong]
    let searchTokens: [String]
    
    init(searchTokens: [String]) {
        self.searchTokens = searchTokens
    }
    
    var filteredSongs: [VTSong] {
        if searchTokens.isEmpty {
            return allSongs
        }
        
        return allSongs.filter { song in
            // Check if ANY token matches (OR logic across tokens for broad search)
            // or modify to ALL if strict matching is desired.
            // Based on context of "Semantic Search" (Lemma expansion), ANY is usually correct
            // because "Running" -> ["Running", "Run"]. We want songs with EITHER.
            
            searchTokens.contains { token in
                song.title.localizedStandardContains(token) ||
                song.artist.localizedStandardContains(token) ||
                song.tags.contains { tag in
                    tag.name.localizedStandardContains(token)
                }
            }
        }
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredSongs) { song in
                SongRowView(song: song)
            }
        }
    }
}
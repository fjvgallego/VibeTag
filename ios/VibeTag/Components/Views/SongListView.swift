import SwiftUI
import SwiftData

struct SongListView: View {
    @Query(sort: \VTSong.dateAdded, order: .reverse) private var allSongs: [VTSong]
    let searchText: String
    let filter: FilterScope
    let sortOption: SortOption
    let sortOrder: SortOrder
    
    init(searchText: String, filter: FilterScope, sortOption: SortOption, sortOrder: SortOrder) {
        self.searchText = searchText
        self.filter = filter
        self.sortOption = sortOption
        self.sortOrder = sortOrder
    }
    
    var filteredSongs: [VTSong] {
        var result = allSongs
        
        // 1. Apply Scope Filter
        switch filter {
        case .all:
            break
        case .untagged:
            result = result.filter { $0.tags.isEmpty }
        case .system:
            result = result.filter { song in
                song.tags.contains { $0.isSystemTag }
            }
        case .user:
            result = result.filter { song in
                song.tags.contains { !$0.isSystemTag }
            }
        }
        
        // 2. Apply Search
        if !searchText.isEmpty {
            result = result.filter { song in
                song.title.localizedStandardContains(searchText) ||
                song.artist.localizedStandardContains(searchText) ||
                song.tags.contains { tag in
                    tag.name.localizedStandardContains(searchText)
                }
            }
        }
        
        // 3. Apply Sort
        let isAscending = sortOrder == .ascending
        
        switch sortOption {
        case .songName:
            result.sort { 
                let comparison = $0.title.localizedCaseInsensitiveCompare($1.title)
                return isAscending ? comparison == .orderedAscending : comparison == .orderedDescending
            }
        case .artistName:
            result.sort { 
                let comparison = $0.artist.localizedCaseInsensitiveCompare($1.artist)
                return isAscending ? comparison == .orderedAscending : comparison == .orderedDescending
            }
        case .albumName:
            result.sort {
                let comparison = ($0.album ?? "").localizedCaseInsensitiveCompare($1.album ?? "")
                return isAscending ? comparison == .orderedAscending : comparison == .orderedDescending
            }
        case .dateAdded:
            result.sort { 
                isAscending ? $0.dateAdded < $1.dateAdded : $0.dateAdded > $1.dateAdded
            }
        case .tagCount:
            result.sort { 
                isAscending ? $0.tags.count < $1.tags.count : $0.tags.count > $1.tags.count
            }
        }
        
        return result
    }
    
    var body: some View {
        let songs = filteredSongs

        Group {
        if songs.isEmpty {
            List {
                VStack(spacing: 24) {
                    Spacer().frame(height: 60)
                    
                    Image(systemName: allSongs.isEmpty ? "music.note.list" : "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        Text(allSongs.isEmpty ? "Tu biblioteca está vacía" : "Sin resultados")
                            .font(.nunito(.title3, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(allSongs.isEmpty ? "Sincroniza con Apple Music para empezar a organizar tu música." : "No encontramos ninguna canción que coincida con tu búsqueda o filtros.")
                            .font(.nunito(.subheadline, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        } else {
            List {
                ForEach(songs) { song in
                    SongRowView(song: song)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
                
                Color.clear
                    .frame(height: 100)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        }
        .animation(.easeInOut(duration: 0.3), value: songs.isEmpty)
    }
}

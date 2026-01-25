import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AppRouter.self) private var router
    
    // SwiftData Query
    @Query(sort: \VTSong.dateAdded, order: .reverse) private var songs: [VTSong]
    
    var body: some View {
        List {
            ForEach(songs) { song in
                Button {
                    router.navigate(to: .songDetail(songID: song.id))
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(song.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(song.artist)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText)
        .navigationTitle("Home")
    }
}

#Preview {
    HomeView()
        .environment(AppRouter())
        .modelContainer(for: [VTSong.self, Tag.self], inMemory: true)
}

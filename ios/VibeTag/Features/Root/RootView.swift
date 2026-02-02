import SwiftUI
import SwiftData

struct RootView: View {
    @State private var router = AppRouter()
    @State private var viewModel = RootViewModel()

    var body: some View {
        Group {
            if viewModel.isAuthorized {
                NavigationStack(path: $router.path) {
                    HomeView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .songDetail(let songID):
                                SongDetailDestinationView(songID: songID)
                            case .tagDetail(let tagID):
                                Text("Tag Detail: \(tagID)") // Placeholder
                            }
                        }
                }
                .environment(router)
            } else {
                WelcomeView {
                    viewModel.requestMusicPermissions()
                }
            }
        }
        .onAppear {
            viewModel.updateAuthorizationStatus()
        }
    }
}

struct SongDetailDestinationView: View {
    let songID: String
    @Query private var songs: [VTSong]
    @Environment(\.modelContext) private var modelContext
    @Environment(VibeTagSyncEngine.self) private var syncEngine
    
    init(songID: String) {
        self.songID = songID
        self._songs = Query(filter: #Predicate<VTSong> { $0.id == songID })
    }
    
    var body: some View {
        if let song = songs.first {
            let localRepo = LocalSongStorageRepositoryImpl(modelContext: modelContext)
            SongDetailView(viewModel: SongDetailViewModel(
                song: song,
                useCase: AnalyzeSongUseCase(
                    remoteRepository: AppleMusicSongRepositoryImpl(),
                    localRepository: localRepo
                ),
                repository: localRepo,
                syncEngine: syncEngine
            ))
        } else {
            ContentUnavailableView("Song Not Found", systemImage: "music.note.list")
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [VTSong.self, Tag.self], inMemory: true)
}

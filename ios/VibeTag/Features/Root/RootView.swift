import SwiftUI
import SwiftData

struct RootView: View {
    let container: AppContainer
    @State private var router = AppRouter()
    @State private var viewModel = RootViewModel()
    @State private var sessionManager: SessionManager
    @State private var syncEngine: VibeTagSyncEngine
    @Environment(\.scenePhase) private var scenePhase
    
    init(container: AppContainer) {
        self.container = container
        
        let sessionManager = SessionManager(tokenStorage: container.tokenStorage, authRepository: container.authRepo)
        self._sessionManager = State(initialValue: sessionManager)
        self._syncEngine = State(initialValue: VibeTagSyncEngine(localRepo: container.localRepo, sessionManager: sessionManager))
    }

    var body: some View {
        Group {
            if viewModel.isAuthorized {
                NavigationStack(path: $router.path) {
                    HomeView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .songDetail(let songID):
                                SongDetailDestinationView(songID: songID, container: container)
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
        .environment(sessionManager)
        .environment(syncEngine)
        .onAppear {
            viewModel.updateAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await syncEngine.pullRemoteData()
                    await syncEngine.syncPendingChanges()
                }
            }
        }
    }
}

struct SongDetailDestinationView: View {
    let songID: String
    let container: AppContainer
    @Query private var songs: [VTSong]
    @Environment(\.modelContext) private var modelContext
    @Environment(VibeTagSyncEngine.self) private var syncEngine
    
    init(songID: String, container: AppContainer) {
        self.songID = songID
        self.container = container
        self._songs = Query(filter: #Predicate<VTSong> { $0.id == songID })
    }
    
    var body: some View {
        if let song = songs.first {
            SongDetailView(song: song, container: container, syncEngine: syncEngine)
        } else {
            ContentUnavailableView("Song Not Found", systemImage: "music.note.list")
        }
    }
}

#Preview {
    // Mock container for preview
    let container = AppContainer(modelContext: try! ModelContainer(for: VTSong.self, Tag.self).mainContext)
    RootView(container: container)
        .modelContainer(for: [VTSong.self, Tag.self], inMemory: true)
}

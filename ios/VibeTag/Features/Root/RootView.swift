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
                    MainTabView(container: container)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .songDetail(let songID):
                                SongDetailDestinationView(songID: songID, container: container)
                            case .tagDetail(let tagID):
                                Text("Tag Detail: \(tagID)") // Placeholder
                            case .generatePlaylist(let prompt):
                                CreatePlaylistView(generatePlaylistUseCase: container.generatePlaylistUseCase, prompt: prompt)
                            }
                        }
                }
                .environment(router)
            } else {
                WelcomeView(
                    onRequestPermissions: {
                        viewModel.requestMusicPermissions()
                    },
                    onContinueAsGuest: {
                        viewModel.continueAsGuest()
                    }
                )
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
                    do {
                        try await syncEngine.pullRemoteData()
                        await syncEngine.syncPendingChanges()
                    } catch {
                        // Log or handle sync failure appropriately
                        print("Background sync failed: \(error)")
                    }
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
        let songID = songID
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
    let modelContainer = try! ModelContainer(for: VTSong.self, Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let container = AppContainer(modelContext: modelContainer.mainContext)
    return RootView(container: container)
        .modelContainer(modelContainer)
}

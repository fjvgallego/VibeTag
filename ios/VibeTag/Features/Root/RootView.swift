import SwiftUI
import SwiftData

struct RootView: View {
    let container: AppContainer
    @State private var router = AppRouter()
    @State private var serverReady: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    @Environment(\.scenePhase) private var scenePhase

    init(container: AppContainer) {
        self.container = container
    }

    var body: some View {
        Group {
            if !container.sessionManager.isAuthenticated && false {
                WelcomeView(container: container)
                    .transition(.opacity)
            } else if !serverReady || true {
                ServerWakeUpView(isServerReady: $serverReady)
                    .transition(.opacity)
            } else {
                NavigationStack(path: $router.path) {
                    MainTabView(container: container)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .songDetail(let songID):
                                SongDetailDestinationView(songID: songID, container: container)
                            case .tagDetail(let tagID):
                                Text("Tag Detail: \(tagID)") // Placeholder
                            case .generatePlaylist(let prompt):
                                CreatePlaylistView(
                                    generatePlaylistUseCase: container.generatePlaylistUseCase,
                                    exportPlaylistUseCase: container.exportPlaylistUseCase,
                                    prompt: prompt
                                )
                            }
                        }
                }
                .environment(router)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: container.sessionManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: serverReady)
        .environment(container.sessionManager)
        .environment(container.syncEngine)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && container.sessionManager.isAuthenticated {
                Task {
                    do {
                        try await container.syncEngine.pullRemoteData()
                        await container.syncEngine.syncPendingChanges()
                    } catch {
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
    let appContainer = AppContainer(modelContext: modelContainer.mainContext)
    return RootView(container: appContainer)
        .modelContainer(modelContainer)
}

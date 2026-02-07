import SwiftUI

struct MainTabView: View {
    let container: AppContainer
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        TabView {
            NavigationStack(path: Bindable(router).path) {
                HomeView(container: container)
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("Biblioteca", systemImage: "music.note.house.fill")
            }
            
            NavigationStack(path: Bindable(router).path) {
                TagsView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("Etiquetas", systemImage: "tag.fill")
            }
            
            NavigationStack(path: Bindable(router).path) {
                SettingsView(container: container)
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("Ajustes", systemImage: "gearshape.fill")
            }
        }
        .accentColor(Color("appleMusicRed"))
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
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

//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let modelContainer = try! ModelContainer(for: VTSong.self, Tag.self, configurations: config)
//    let appContainer = AppContainer(modelContext: modelContainer.mainContext)
//    let sessionManager = SessionManager(tokenStorage: appContainer.tokenStorage, authRepository: appContainer.authRepo)
//    let syncEngine = VibeTagSyncEngine(localRepo: appContainer.localRepo, sessionManager: sessionManager)
//    
//    return MainTabView(container: appContainer)
//        .environment(AppRouter())
//        .environment(sessionManager)
//        .environment(syncEngine)
//        .modelContainer(modelContainer)
//}

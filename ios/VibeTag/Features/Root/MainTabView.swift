import SwiftUI

struct MainTabView: View {
    let container: AppContainer
    
    var body: some View {
        TabView {
            HomeView(container: container)
                .tabItem {
                    Label("Biblioteca", systemImage: "music.note.house.fill")
                }
            
            TagsView()
                .tabItem {
                    Label("Etiquetas", systemImage: "tag.fill")
                }
            
            SettingsView(container: container)
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
        }
        .accentColor(Color("appleMusicRed"))
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

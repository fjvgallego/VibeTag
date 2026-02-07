import SwiftUI

struct MainTabView: View {
    let container: AppContainer
    
    var body: some View {
        TabView {
            HomeView(container: container)
                .tabItem {
                    Label("Biblioteca", systemImage: "music.note.house.fill")
                }
            
            TagsPlaceholderView()
                .tabItem {
                    Label("Etiquetas", systemImage: "tag.fill")
                }
            
            SettingsPlaceholderView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
        }
        .accentColor(Color("appleMusicRed"))
    }
}

// MARK: - Placeholders

struct TagsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Etiquetas", systemImage: "tag.fill")
        } description: {
            Text("Tus etiquetas personalizadas aparecerán aquí.")
        }
        .navigationTitle("Etiquetas")
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        List {
            Section("Cuenta") {
                Text("Perfil de Usuario")
                Text("Suscripción")
            }
            
            Section("App") {
                Text("Notificaciones")
                Text("Privacidad")
            }
        }
        .navigationTitle("Ajustes")
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

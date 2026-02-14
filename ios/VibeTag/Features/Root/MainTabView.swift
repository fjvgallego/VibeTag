import SwiftUI

struct MainTabView: View {
    let container: AppContainer
    
    var body: some View {
        TabView {
            HomeView(container: container)
                .tabItem {
                    Label("Biblioteca", systemImage: "music.note.house.fill")
                }
            
            TagsView(container: container)
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
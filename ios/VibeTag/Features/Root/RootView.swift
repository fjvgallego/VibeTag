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
                                Text("Song Detail: \(songID)") // Placeholder
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

#Preview {
    RootView()
        .modelContainer(for: [VTSong.self, Tag.self], inMemory: true)
}

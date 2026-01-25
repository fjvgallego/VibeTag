import SwiftUI
import SwiftData

struct RootView: View {
    @State private var router = AppRouter()
    @State private var viewModel = RootViewModel()

    var body: some View {
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
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Song.self, Tag.self], inMemory: true)
}

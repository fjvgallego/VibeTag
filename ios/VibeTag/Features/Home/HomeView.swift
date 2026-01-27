import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            SongListView(searchTokens: viewModel.searchTokens)
        }
        .searchable(text: $viewModel.searchText)
        .navigationTitle("Home")
        .toolbar {
            Button("Sync Library") {
                Task {
                    await viewModel.syncLibrary(modelContext: modelContext)
                }
            }
            .disabled(viewModel.isSyncing)
        }
        .alert("Sync Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}

#Preview {
    HomeView()
        .environment(AppRouter())
        .modelContainer(for: [VTSong.self, Tag.self], inMemory: true)
}

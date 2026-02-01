import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showingLogin = false
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionManager.self) var sessionManager
    
    var body: some View {
        ScrollView {
            SongListView(searchTokens: viewModel.searchTokens)
        }
        .searchable(text: $viewModel.searchText)
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button("Sync Library") {
                        Task {
                            await viewModel.syncLibrary(modelContext: modelContext)
                        }
                    }
                    .disabled(viewModel.isSyncing)
                    
                    if sessionManager.isAuthenticated {
                        Menu {
                            Button("Logged in", action: {}).disabled(true)
                            Button("Logout", role: .destructive) {
                                sessionManager.logout()
                            }
                        } label: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                        }
                    } else {
                        Button {
                            showingLogin = true
                        } label: {
                            Image(systemName: "person.circle")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
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
        .environment(SessionManager())
        .modelContainer(for: [VTSong.self, Tag.self], inMemory: true)
}

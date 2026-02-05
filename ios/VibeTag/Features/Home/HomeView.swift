import SwiftUI
import SwiftData

struct HomeView: View {
    let container: AppContainer
    @State private var viewModel: HomeViewModel
    @State private var showingLogin = false
    @State private var showingDeleteConfirmation = false
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionManager.self) var sessionManager
    @Environment(VibeTagSyncEngine.self) var syncEngine
    
    init(container: AppContainer) {
        self.container = container
        self._viewModel = State(initialValue: HomeViewModel(
            analyzeUseCase: container.analyzeSongUseCase,
            localRepository: container.localRepo
        ))
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isAnalyzing {
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.analysisProgress) {
                        Text(viewModel.analysisStatus)
                            .font(.caption)
                    }
                    .progressViewStyle(.linear)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            
            SongListView(searchTokens: viewModel.searchTokens)
        }
        .searchable(text: $viewModel.searchText)
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if sessionManager.isAuthenticated {
                        Button {
                            router.navigate(to: .generatePlaylist)
                        } label: {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                        }
                    }
                    
                    if !viewModel.isAnalyzing {
                        Button("✨ Analyze Library") {
                            Task {
                                await viewModel.analyzeLibrary()
                            }
                        }
                    }
                    
                    Button("Sync Library") {
                        Task {
                            await viewModel.syncLibrary(modelContext: modelContext)
                            await syncEngine.pullRemoteData()
                        }
                    }
                    .disabled(viewModel.isSyncing)
                    
                    if sessionManager.isAuthenticated {
                        Menu {
                            Button("Logged in", action: {}).disabled(true)
                            Button("Logout") {
                                sessionManager.logout()
                            }
                            Button("Delete Account", role: .destructive) {
                                showingDeleteConfirmation = true
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
        .confirmationDialog("Are you sure?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                Task {
                    await sessionManager.deleteAccount()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: VTSong.self, Tag.self, configurations: config)
    let appContainer = AppContainer(modelContext: container.mainContext)
    let sessionManager = SessionManager(tokenStorage: appContainer.tokenStorage, authRepository: appContainer.authRepo)
    let syncEngine = VibeTagSyncEngine(localRepo: appContainer.localRepo, sessionManager: sessionManager)
    
    HomeView(container: appContainer)
        .environment(AppRouter())
        .environment(sessionManager)
        .environment(syncEngine)
        .modelContainer(container)
}

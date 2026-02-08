import SwiftUI
import SwiftData

struct HomeView: View {
    let container: AppContainer
    @State private var viewModel: HomeViewModel
    @State private var showingLogin = false
    @State private var showingDeleteConfirmation = false
    @State private var showingVibeSheet = false
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
        ZStack(alignment: .bottom) {
            // Layer 0: Background
            backgroundView
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Mi Biblioteca")
                        .font(.nunito(.largeTitle, weight: .bold))
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    if viewModel.isAnalyzing {
                        VStack(spacing: 12) {
                            ProgressView(value: viewModel.analysisProgress) {
                                Text(viewModel.analysisStatus)
                                    .font(.nunito(.caption))
                            }
                            .progressViewStyle(.linear)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    SongListView(searchTokens: viewModel.searchTokens)
                        .padding(.bottom, 100) // Space for the floating bar
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Buscar canciones o vibes...")
            
            // Layer 2: Floating Bar
            FloatingVibeBar {
                showingVibeSheet = true
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingVibeSheet) {
            VibeInputSheet { vibe in
                showingVibeSheet = false
                router.navigate(to: .generatePlaylist(prompt: vibe))
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await viewModel.analyzeLibrary() }
                    } label: {
                        Label("Analizar Biblioteca", systemImage: "sparkles")
                    }
                    .disabled(viewModel.isAnalyzing)
                    
                    Button {
                        Task { await viewModel.performFullSync(modelContext: modelContext, syncEngine: syncEngine) }
                    } label: {
                        Label("Sincronizar", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(viewModel.isSyncing)
                    
                    if sessionManager.isAuthenticated {
                        Divider()
                        Button("Cerrar Sesión", role: .destructive) {
                            sessionManager.logout()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color("appleMusicRed"))
                }
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            RadialGradient(
                stops: [
                    .init(color: Color("appleMusicRed").opacity(0.12), location: 0),
                    .init(color: .clear, location: 0.8)
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            RadialGradient(
                stops: [
                    .init(color: Color("appleMusicRed").opacity(0.08), location: 0),
                    .init(color: .clear, location: 0.7)
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color.purple.opacity(0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: 300)
                .ignoresSafeArea()
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

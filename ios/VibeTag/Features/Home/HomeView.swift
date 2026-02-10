import SwiftUI
import SwiftData

struct HomeView: View {
    let container: AppContainer
    @State private var viewModel: HomeViewModel
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
            
            VStack(alignment: .leading, spacing: 0) {
                // Fixed Header Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Mi Biblioteca")
                        .font(.nunito(.largeTitle, weight: .bold))
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Search Bar & Sort
                    HStack(spacing: 12) {
                        VTSearchBar(text: $viewModel.searchText, placeholder: "Buscar canciones, artistas...")
                        
                        Menu {
                            Section("Ordenar por") {
                                Picker("Criterio", selection: $viewModel.selectedSort) {
                                    ForEach(SortOption.allCases) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                            }
                            
                            Section("Orden") {
                                Picker("Sentido", selection: $viewModel.selectedOrder) {
                                    ForEach(SortOrder.allCases) { order in
                                        Label(order.rawValue, systemImage: order.icon).tag(order)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 20))
                                .foregroundColor(Color("appleMusicRed"))
                                .padding(10)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(FilterScope.allCases) { scope in
                                VTFilterChip(
                                    title: scope.rawValue,
                                    isSelected: viewModel.selectedFilter == scope
                                ) {
                                    viewModel.selectedFilter = scope
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Library Analysis Status
                    AnalysisStatusView(viewModel: viewModel)
                        .padding(.horizontal)
                }
                .padding(.bottom, 16)
                
                // Scrollable Song List
                if viewModel.isAppleMusicLinked {
                    if viewModel.isSyncing && viewModel.totalSongsCount == 0 {
                        VStack(spacing: 20) {
                            Spacer()
                            ProgressView()
                                .controlSize(.large)
                                .tint(Color("appleMusicRed"))
                            
                            VStack(spacing: 8) {
                                Text("Sincronizando biblioteca")
                                    .font(.nunito(.headline, weight: .bold))
                                
                                Text("Estamos importando tus canciones de Apple Music. Esto puede tardar unos momentos.")
                                    .font(.nunito(.subheadline, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        SongListView(
                            searchText: viewModel.searchText,
                            filter: viewModel.selectedFilter,
                            sortOption: viewModel.selectedSort,
                            sortOrder: viewModel.selectedOrder
                        )
                        .refreshable {
                            await viewModel.syncLibrary(modelContext: modelContext)
                        }
                    }
                } else {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("Enlaza tu música")
                                .font(.nunito(.title2, weight: .bold))
                            
                            Text("Conecta Apple Music para empezar a etiquetar tus canciones favoritas con IA.")
                                .font(.nunito(.subheadline, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        PrimaryActionButton("Conectar Apple Music", icon: "music.note") {
                            viewModel.requestMusicPermissions()
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
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
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .onAppear {
            viewModel.updateAuthorizationStatus()
            
            // If the user just authorized (e.g. from WelcomeView), 
            // the library might be empty. Trigger an initial sync.
            if viewModel.isAppleMusicLinked && viewModel.totalSongsCount == 0 {
                Task {
                    await viewModel.syncLibrary(modelContext: modelContext)
                }
            }
        }
        .onChange(of: viewModel.isAppleMusicLinked) { _, isLinked in
            if isLinked {
                Task {
                    await viewModel.syncLibrary(modelContext: modelContext)
                }
            }
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

private struct AnalysisStatusView: View {
    let viewModel: HomeViewModel
    
    var body: some View {
        Group {
            if !viewModel.isAppleMusicLinked {
                EmptyView()
            } else if viewModel.isSyncing {
                // State: Syncing
                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Sincronizando biblioteca...")
                        .font(.nunito(.subheadline, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
            } else if viewModel.isAnalyzing {
                // State B: Analyzing (Active)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Analizando biblioteca...")
                            .font(.nunito(.subheadline, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(viewModel.currentAnalyzedCount) / \(viewModel.totalToAnalyzeCount)")
                            .font(.nunito(.caption, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: viewModel.analysisProgress)
                        .progressViewStyle(.linear)
                        .tint(Color("appleMusicRed"))
                }
                .padding(16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
            } else if viewModel.unanalyzedCount > 0 {
                // State A: Analysis Needed (Idle)
                HStack(spacing: 12) {
                    Text("\(viewModel.unanalyzedCount) canciones sin etiquetar")
                        .font(.nunito(.subheadline, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        Task { await viewModel.analyzeLibrary() }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                            Text("Analizar con IA")
                                .font(.nunito(.caption, weight: .black))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color("appleMusicRed"))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
                
            } else if viewModel.totalSongsCount > 0 {
                // State C: All Complete
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .bold))
                    Text("Biblioteca totalmente analizada")
                        .font(.nunito(.caption, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.05))
                .clipShape(Capsule())
            } else {
                EmptyView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAnalyzing)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isSyncing)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.unanalyzedCount)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAppleMusicLinked)
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

import SwiftUI
import SwiftData

struct HomeView: View {
    let container: AppContainer
    @State private var viewModel: HomeViewModel
    @State private var showingVibeSheet = false
    @Environment(AppRouter.self) private var router
    @Environment(SessionManager.self) var sessionManager

    init(container: AppContainer) {
        self.container = container
        self._viewModel = State(initialValue: HomeViewModel(
            libraryActionService: container.libraryActionService
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundView

            VStack(alignment: .leading, spacing: 0) {
                LibraryHeaderSection(viewModel: viewModel)
                    .padding(.bottom, 16)

                if viewModel.isAppleMusicLinked {
                    if viewModel.isSyncing && viewModel.totalSongsCount == 0 {
                        LibrarySyncingView()
                    } else {
                        SongListView(
                            searchText: viewModel.searchText,
                            filter: viewModel.selectedFilter,
                            sortOption: viewModel.selectedSort,
                            sortOrder: viewModel.selectedOrder
                        )
                        .refreshable {
                            await viewModel.syncLibrary()
                        }
                    }
                } else {
                    AppleMusicNotLinkedView {
                        viewModel.requestMusicPermissions()
                    }
                }
            }

            FloatingVibeBar { showingVibeSheet = true }
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
                LibraryToolbarMenu(
                    viewModel: viewModel,
                    sessionManager: sessionManager
                )
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
            if viewModel.isAppleMusicLinked && viewModel.totalSongsCount == 0 {
                Task { await viewModel.syncLibrary() }
            }
        }
        .onChange(of: viewModel.isAppleMusicLinked) { _, isLinked in
            if isLinked { Task { await viewModel.syncLibrary() } }
        }
    }

    private var backgroundView: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            RadialGradient(
                stops: [
                    .init(color: Color("appleMusicRed").opacity(0.12), location: 0),
                    .init(color: .clear, location: 0.8)
                ],
                center: .topTrailing, startRadius: 0, endRadius: 600
            )
            .ignoresSafeArea()

            RadialGradient(
                stops: [
                    .init(color: Color("appleMusicRed").opacity(0.08), location: 0),
                    .init(color: .clear, location: 0.7)
                ],
                center: .bottomLeading, startRadius: 0, endRadius: 500
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

// MARK: - Private subviews

private struct LibraryHeaderSection: View {
    let viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Mi Biblioteca")
                .font(.nunito(.largeTitle, weight: .bold))
                .padding(.horizontal)
                .padding(.top, 10)

            HStack(spacing: 12) {
                VTSearchBar(text: Bindable(viewModel).searchText, placeholder: "Buscar canciones, artistas...")

                Menu {
                    Section("Ordenar por") {
                        Picker("Criterio", selection: Bindable(viewModel).selectedSort) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    }
                    Section("Orden") {
                        Picker("Sentido", selection: Bindable(viewModel).selectedOrder) {
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

            AnalysisStatusView(viewModel: viewModel)
                .padding(.horizontal)
        }
    }
}

private struct LibraryToolbarMenu: View {
    let viewModel: HomeViewModel
    let sessionManager: SessionManager

    var body: some View {
        Menu {
            Button {
                Task { await viewModel.analyzeLibrary() }
            } label: {
                Label("Analizar Biblioteca", systemImage: "sparkles")
            }
            .disabled(viewModel.isAnalyzing)

            Button {
                Task { await viewModel.performFullSync() }
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
        .accessibilityIdentifier("homeToolbarMenu")
    }
}

private struct LibrarySyncingView: View {
    var body: some View {
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
    }
}

private struct AppleMusicNotLinkedView: View {
    let onConnect: () -> Void

    var body: some View {
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
                onConnect()
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AnalysisStatusView: View {
    let viewModel: HomeViewModel

    var body: some View {
        Group {
            if !viewModel.isAppleMusicLinked {
                EmptyView()
            } else if viewModel.isSyncing {
                syncingBanner
            } else if viewModel.isAnalyzing {
                analyzingBanner
            } else if viewModel.unanalyzedCount > 0 {
                analysisNeededBanner
            } else if viewModel.totalSongsCount > 0 {
                allAnalyzedBanner
            } else {
                EmptyView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAnalyzing)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isSyncing)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.unanalyzedCount)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAppleMusicLinked)
    }

    private var syncingBanner: some View {
        HStack(spacing: 12) {
            ProgressView().controlSize(.small)
            Text("Sincronizando biblioteca...")
                .font(.nunito(.subheadline, weight: .bold))
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private var analyzingBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Analizando biblioteca...")
                    .font(.nunito(.subheadline, weight: .bold))
                Spacer()
                Text("\(viewModel.currentAnalyzedCount) / \(viewModel.totalToAnalyzeCount)")
                    .font(.nunito(.caption, weight: .bold))
                    .foregroundColor(.secondary)
                Button(action: { viewModel.cancelAnalysis() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)
            }
            ProgressView(value: viewModel.analysisProgress)
                .progressViewStyle(.linear)
                .tint(Color("appleMusicRed"))
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private var analysisNeededBanner: some View {
        HStack(spacing: 12) {
            Text("\(viewModel.unanalyzedCount) canciones sin etiquetar")
                .font(.nunito(.subheadline, weight: .bold))
            Spacer()
            Button(action: { Task { await viewModel.analyzeLibrary() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").font(.system(size: 14))
                    Text("Analizar con IA").font(.nunito(.caption, weight: .black))
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
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private var allAnalyzedBanner: some View {
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
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try! ModelContainer(for: VTSong.self, Tag.self, configurations: config)
    let appContainer = AppContainer(modelContext: modelContainer.mainContext)

    HomeView(container: appContainer)
        .environment(AppRouter())
        .environment(appContainer.sessionManager)
        .environment(appContainer.syncEngine)
        .modelContainer(modelContainer)
}

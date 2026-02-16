import SwiftUI
import SwiftData

struct TagsView: View {
    @Query private var allTags: [VibeTag.Tag]
    @State private var viewModel: TagsViewModel
    @State private var showingCreateTag = false
    @State private var tagToEdit: VibeTag.Tag? = nil
    @State private var tagToDelete: VibeTag.Tag? = nil
    @State private var showingDeleteConfirmation = false

    let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    init(container: AppContainer) {
        self._viewModel = State(initialValue: TagsViewModel(
            modelContext: container.modelContext,
            syncEngine: container.syncEngine
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Tags Hub")
                        .font(.nunito(.largeTitle, weight: .bold))
                    Spacer()
                    Button {
                        showingCreateTag = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color("appleMusicRed"))
                            .padding(8)
                            .background(Color("appleMusicRed").opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Search Bar & Sort
                HStack(spacing: 12) {
                    VTSearchBar(text: $viewModel.searchText, placeholder: "Buscar etiquetas...")

                    Menu {
                        Section("Ordenar por") {
                            Picker("Criterio", selection: $viewModel.selectedSort) {
                                ForEach(TagSortOption.allCases) { option in
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
                        ForEach(TagFilter.allCases) { filter in
                            VTFilterChip(
                                title: filter.rawValue,
                                isSelected: viewModel.selectedFilter == filter
                            ) {
                                viewModel.selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 16)

            // Scrollable Tags Grid
            ScrollView {
                let filteredTags = viewModel.filteredTags(allTags)

                if filteredTags.isEmpty {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 60)

                        Image(systemName: allTags.isEmpty ? "tag.slash" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.3))

                        VStack(spacing: 8) {
                            Text(allTags.isEmpty ? "No hay etiquetas" : "Sin resultados")
                                .font(.nunito(.title3, weight: .bold))

                            Text(allTags.isEmpty
                                 ? "Crea tu primera etiqueta para empezar a organizar tu música de forma personalizada."
                                 : "No encontramos ninguna etiqueta que coincida con tu búsqueda o filtros.")
                                .font(.nunito(.subheadline, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        if allTags.isEmpty {
                            Button(action: { showingCreateTag = true }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Crear Etiqueta")
                                }
                                .font(.nunito(.subheadline, weight: .bold))
                                .foregroundColor(.appleMusicRed)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.appleMusicRed.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 20) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredTags) { tag in
                                TagCell(
                                    tag: tag,
                                    onEdit: { tagToEdit = tag },
                                    onDelete: {
                                        tagToDelete = tag
                                        showingDeleteConfirmation = true
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredTags.map(\.id))
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingCreateTag) {
            CreateTagSheet { name, hexColor, description in
                viewModel.createTag(name: name, hexColor: hexColor, description: description, existingTags: allTags)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $tagToEdit) { tag in
            CreateTagSheet(
                tagName: tag.name,
                tagDescription: tag.tagDescription,
                selectedColor: Color(hex: tag.hexColor) ?? .appleMusicRed
            ) { name, hexColor, description in
                viewModel.updateTag(tag, name: name, hexColor: hexColor, description: description)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("¿Eliminar etiqueta?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Eliminar \"\(tagToDelete?.name ?? "")\"", role: .destructive) {
                if let tag = tagToDelete {
                    viewModel.deleteTag(tag)
                    tagToDelete = nil
                }
            }
            Button("Cancelar", role: .cancel) {
                tagToDelete = nil
            }
        } message: {
            Text("Esta acción no se puede deshacer y se quitará de todas las canciones.")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try! ModelContainer(for: VibeTag.Tag.self, VTSong.self, configurations: config)
    let appContainer = AppContainer(modelContext: modelContainer.mainContext)

    return NavigationStack {
        TagsView(container: appContainer)
            .modelContainer(modelContainer)
            .environment(appContainer.syncEngine)
    }
}

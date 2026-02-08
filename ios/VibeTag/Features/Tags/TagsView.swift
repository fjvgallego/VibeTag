import SwiftUI
import SwiftData

struct TagsView: View {
    @Query private var allTags: [Tag]
    @State private var viewModel = TagsViewModel()
    @State private var showingCreateTag = false
    @State private var tagToEdit: Tag? = nil
    @State private var tagToDelete: Tag? = nil
    @State private var showingDeleteConfirmation = false
    @Environment(\.modelContext) private var modelContext
    
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
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
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 20) {
                    // Custom Segmented Control
                    CustomSegmentedControl(selection: $viewModel.selectedFilter, items: TagFilter.allCases)
                        .padding(.horizontal)
                    
                    // Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredTags(allTags)) { tag in
                            TagCell(
                                tag: tag,
                                onEdit: {
                                    tagToEdit = tag
                                },
                                onDelete: {
                                    tagToDelete = tag
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 10)
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .searchable(text: $viewModel.searchText, prompt: "Buscar etiquetas...")
        .sheet(isPresented: $showingCreateTag) {
            CreateTagSheet { name, hexColor in
                let newTag = Tag(name: name, hexColor: hexColor)
                modelContext.insert(newTag)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $tagToEdit) { tag in
            CreateTagSheet(tagName: tag.name, selectedColor: Color(hex: tag.hexColor) ?? .appleMusicRed) { name, hexColor in
                tag.name = name
                tag.hexColor = hexColor
                try? modelContext.save()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("¿Eliminar etiqueta?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Eliminar \"\(tagToDelete?.name ?? "")\"", role: .destructive) {
                if let tag = tagToDelete {
                    modelContext.delete(tag)
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
    let container = try! ModelContainer(for: Tag.self, VTSong.self, configurations: config)
    return NavigationStack {
        TagsView()
            .modelContainer(container)
    }
}

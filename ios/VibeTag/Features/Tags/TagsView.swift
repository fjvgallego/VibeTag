import SwiftUI
import SwiftData

struct TagsView: View {
    @Query private var allTags: [Tag]
    @State private var viewModel = TagsViewModel()
    @State private var showingCreateTag = false
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
                    // Filter Picker
                    Picker("Filtro", selection: $viewModel.selectedFilter) {
                        ForEach(TagFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredTags(allTags)) { tag in
                            TagCell(tag: tag) {
                                // Action for ellipsis menu
                            }
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

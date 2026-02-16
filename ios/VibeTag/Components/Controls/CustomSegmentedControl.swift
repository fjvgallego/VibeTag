import SwiftUI

struct CustomSegmentedControl<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String {
    @Binding var selection: T
    let items: [T]
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selection = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.nunito(.subheadline, weight: selection == item ? .bold : .medium))
                        .foregroundColor(selection == item ? Color("appleMusicRed") : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            if selection == item {
                                Capsule()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemFill).opacity(0.4))
        .clipShape(Capsule())
    }
}

#Preview {
    @Previewable @State var selection: TagFilter = .all
    CustomSegmentedControl(selection: $selection, items: TagFilter.allCases)
        .padding()
}

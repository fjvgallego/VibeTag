import SwiftUI

struct TagCell: View {
    let tag: Tag
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row
            HStack {
                if tag.isSystemTag {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .indigo, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 14, height: 14)
                        .shadow(color: .purple.opacity(0.3), radius: 4)
                } else {
                    Circle()
                        .fill(Color(hex: tag.hexColor) ?? .gray)
                        .frame(width: 12, height: 12)
                }
                
                Spacer()
                
                if !tag.isSystemTag {
                    Menu {
                        Button(action: onEdit) {
                            Label("Editar", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: onDelete) {
                            Label("Eliminar", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .bold))
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                } else {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple.opacity(0.6))
                        .font(.system(size: 14, weight: .bold))
                        .padding(8)
                }
            }
            
            Spacer()
            
            // Tag Name
            Text(tag.name)
                .font(.nunito(.title3, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            
            // Song Count
            HStack(spacing: 4) {
                Image(systemName: "music.note")
                    .font(.system(size: 10))
                Text("\(tag.songs.count) canciones")
                    .font(.nunito(.caption, weight: .medium))
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(height: 140)
        .background(
            ZStack {
                Color(.secondarySystemGroupedBackground)
                
                if tag.isSystemTag {
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.12),
                            Color.blue.opacity(0.05),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        colors: [
                            (Color(hex: tag.hexColor) ?? .gray).opacity(0.12),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    tag.isSystemTag ? 
                    AnyShapeStyle(LinearGradient(colors: [.purple.opacity(0.2), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                    AnyShapeStyle((Color(hex: tag.hexColor) ?? .gray).opacity(0.1)), 
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    TagCell(tag: Tag(name: "Dreamy", hexColor: "#FF2D55"))
        .padding()
        .background(Color(.systemGroupedBackground))
}

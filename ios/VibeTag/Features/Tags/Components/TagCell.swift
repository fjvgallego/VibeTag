import SwiftUI

struct TagCell: View {
    let tag: Tag
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row
            HStack {
                Circle()
                    .fill(Color(hex: tag.hexColor) ?? .gray)
                    .frame(width: 12, height: 12)
                
                Spacer()
                
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
                
                LinearGradient(
                    colors: [
                        (Color(hex: tag.hexColor) ?? .gray).opacity(0.12),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke((Color(hex: tag.hexColor) ?? .gray).opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    TagCell(tag: Tag(name: "Dreamy", hexColor: "#FF2D55"))
        .padding()
        .background(Color(.systemGroupedBackground))
}

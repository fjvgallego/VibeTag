import SwiftUI

struct CreateTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tagName: String
    @State private var selectedColor: Color
    private var isEditing: Bool
    
    var onSave: (String, String) -> Void
    
    init(tagName: String = "", selectedColor: Color = .appleMusicRed, onSave: @escaping (String, String) -> Void) {
        self._tagName = State(initialValue: tagName)
        self._selectedColor = State(initialValue: selectedColor)
        self.isEditing = !tagName.isEmpty
        self.onSave = onSave
    }
    
    let colorPalette: [Color] = [
        .appleMusicRed, .orange, .yellow, .green, .blue, .indigo, .purple, .pink, .gray
    ]
    
    private var isCustomColor: Bool {
        guard let selectedHex = selectedColor.toHex()?.uppercased() else { return false }
        return !colorPalette.contains { $0.toHex()?.uppercased() == selectedHex }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(isEditing ? "Editar Etiqueta" : "Nueva Etiqueta")
                    .font(.nunito(.title, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(isEditing ? "Actualiza el estilo de tu etiqueta." : "Organiza tu música a tu manera.")
                    .font(.nunito(.subheadline, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Name Input
            VStack(alignment: .leading, spacing: 10) {
                Text("NOMBRE")
                    .font(.nunito(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                TextField("Nombre de la etiqueta...", text: $tagName)
                    .font(.nunito(.body))
                    .padding(16)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
            }
            
            // Color Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("ELIGE UN COLOR")
                    .font(.nunito(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(colorPalette, id: \.self) { color in
                            ColorCircle(color: color, isSelected: selectedColor.toHex()?.uppercased() == color.toHex()?.uppercased()) {
                                selectedColor = color
                            }
                        }
                        
                        // Custom Color Picker
                        ZStack {
                            // Custom UI Layer
                            ZStack {
                                if isCustomColor {
                                    Circle()
                                        .fill(selectedColor)
                                } else {
                                    Circle()
                                        .fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                                }
                                
                                Circle()
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                
                                if isCustomColor {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 3)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .allowsHitTesting(false)
                            
                            // Interaction Layer
                            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                                .labelsHidden()
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                .opacity(0.02)
                                .zIndex(1)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
            }
            
            Spacer()
            
            // Action Button
            PrimaryActionButton(isEditing ? "Editar Etiqueta" : "Crear Etiqueta", icon: isEditing ? "pencil" : "plus") {
                onSave(tagName, selectedColor.toHex() ?? "#8E8E93")
                dismiss()
            }
            .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
        }
        .padding([.horizontal, .bottom], 24)
        .background(.ultraThinMaterial)
    }
}

private struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateTagSheet(onSave: { _, _ in })
}

import SwiftUI

struct CreateTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tagName: String
    @State private var tagDescription: String
    @State private var selectedColor: Color
    private var isEditing: Bool
    
    var onSave: (String, String, String?) -> Void
    
    init(tagName: String = "", tagDescription: String? = nil, selectedColor: Color = .appleMusicRed, onSave: @escaping (String, String, String?) -> Void) {
        self._tagName = State(initialValue: tagName)
        self._tagDescription = State(initialValue: tagDescription ?? "")
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
                HStack {
                    Text("NOMBRE")
                        .font(.nunito(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(tagName.count)/20")
                        .font(.nunito(size: 10, weight: .medium))
                        .foregroundColor(tagName.count >= 20 ? .red : .secondary)
                }
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
                    .onChange(of: tagName) { _, newValue in
                        if newValue.count > 20 {
                            tagName = String(newValue.prefix(20))
                        }
                    }
            }
            
            // Description Input
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("DESCRIPCIÓN (OPCIONAL)")
                        .font(.nunito(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(tagDescription.count)/60")
                        .font(.nunito(size: 10, weight: .medium))
                        .foregroundColor(tagDescription.count >= 60 ? .red : .secondary)
                }
                .padding(.horizontal, 4)
                
                TextField("Añade una descripción...", text: $tagDescription, axis: .vertical)
                    .font(.nunito(.body))
                    .lineLimit(3...6)
                    .padding(16)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
                    .onChange(of: tagDescription) { _, newValue in
                        if newValue.count > 60 {
                            tagDescription = String(newValue.prefix(60))
                        }
                    }
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
                let finalDescription = tagDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : tagDescription
                onSave(tagName, selectedColor.toHex() ?? "#8E8E93", finalDescription)
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
    CreateTagSheet(onSave: { _, _, _ in })
}

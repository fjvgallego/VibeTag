import SwiftUI

struct VibeInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vibeText: String
    
    var initialText: String
    var onGenerate: (String) -> Void
    
    init(initialText: String = "", onGenerate: @escaping (String) -> Void) {
        self.initialText = initialText
        self._vibeText = State(initialValue: initialText)
        self.onGenerate = onGenerate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cómo te sientes?")
                    .font(.nunito(.title, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("La IA generará la playlist perfecta para ti.")
                    .font(.nunito(.subheadline, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Input Area
            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if vibeText.isEmpty {
                        Text("Describe tu vibe...")
                            .font(.nunito(.body))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                    
                    TextEditor(text: $vibeText)
                        .font(.nunito(.body))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                
                Image(systemName: "sparkles")
                    .foregroundColor(.appleMusicRed)
                    .padding(16)
            }
            .frame(minHeight: 140)
            .background(Color(.secondarySystemBackground).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            
            Spacer()
            
            // Action Button
            PrimaryActionButton("Generar Playlist", icon: "sparkles") {
                onGenerate(vibeText)
            }
            .disabled(vibeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(vibeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
        }
        .padding(24)
        .background(Color(.systemBackground))
    }
}

#Preview {
    VibeInputSheet(onGenerate: { _ in })
}

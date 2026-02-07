import SwiftUI

struct FloatingVibeBar: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("appleMusicRed"), .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("¿Cómo te sientes?")
                    .font(.nunito(.callout, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .frame(height: 50)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack {
            Spacer()
            FloatingVibeBar {
                print("Vibe input tapped")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

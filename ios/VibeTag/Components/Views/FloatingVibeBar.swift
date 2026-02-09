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
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("appleMusicRed"))
                    .padding(8)
                    .background(Color("appleMusicRed").opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.leading, 20)
            .padding(.trailing, 8)
            .frame(height: 50)
            .glassEffect(.regular)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .contentShape(.rect)
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

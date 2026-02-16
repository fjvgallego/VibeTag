import SwiftUI

struct FloatingVibeBar: View {
    let action: () -> Void
    @State private var isVisible = false

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
        .buttonStyle(VibeBarButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

private struct VibeBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
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

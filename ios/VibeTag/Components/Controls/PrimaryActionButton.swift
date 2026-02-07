import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.nunito(.headline, weight: .bold))
                }
                
                Text(title)
                    .font(.nunito(.headline, weight: .bold))
            }
            .padding(.horizontal, 16)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.appleMusicRed)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: Color.appleMusicRed.opacity(0.4), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryActionButton("Get Started", icon: "play.fill") {
            print("Pressed")
        }
        
        PrimaryActionButton("Continue") {
            print("Pressed")
        }
    }
    .padding()
}

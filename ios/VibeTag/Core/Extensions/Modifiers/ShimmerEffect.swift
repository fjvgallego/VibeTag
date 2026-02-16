import SwiftUI

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [.clear, .appleMusicRed.opacity(1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width * 2 + (geometry.size.width * 6 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    @ViewBuilder
    func shimmering(active: Bool = true) -> some View {
        if active {
            modifier(Shimmer())
        } else {
            self
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Generando tu playlist...")
            .font(.nunito(.title, weight: .bold))
            .shimmering()
        
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 200, height: 40)
            .shimmering()
    }
    .padding()
}

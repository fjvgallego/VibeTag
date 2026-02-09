import SwiftUI

struct WelcomeView: View {
    var onRequestPermissions: () -> Void
    var onContinueAsGuest: () -> Void
    
    @State private var animateBackground = false
    
    var body: some View {
        ZStack {
            // Layer 0: Animated background
            backgroundView
            
            VStack(spacing: 0) {
                Spacer()
                
                // Content section
                VStack(spacing: 24) {
                    logoSection
                    
                    VStack(spacing: 8) {
                        Text("VibeTag")
                            .font(.nunito(.largeTitle, weight: .heavy))
                            .foregroundColor(.primary)
                        
                        Text("Tus vibes, tus playlists")
                            .font(.nunito(.title3, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Actions section
                VStack(spacing: 16) {
                    PrimaryActionButton("Conectar Apple Music", icon: "music.note") {
                        onRequestPermissions()
                    }
                    
                    Button(action: onContinueAsGuest) {
                        Text("Enlazar más tarde")
                            .font(.nunito(.callout, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .safeAreaPadding()
        }
    }
    
    private var logoSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white)
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            
            Image(systemName: "music.quarternote.3")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appleMusicRed, .appleMusicRed.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            RadialGradient(
                stops: [
                    .init(color: .appleMusicRed.opacity(0.1), location: 0),
                    .init(color: .clear, location: 0.7)
                ],
                center: animateBackground ? .topLeading : .bottomTrailing,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animateBackground)
            
            RadialGradient(
                stops: [
                    .init(color: Color(red: 0.9, green: 0.9, blue: 1.0).opacity(0.3), location: 0),
                    .init(color: .clear, location: 0.6)
                ],
                center: animateBackground ? .bottomTrailing : .topLeading,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateBackground)
        }
        .onAppear {
            animateBackground = true
        }
    }
}

#Preview {
    WelcomeView(
        onRequestPermissions: {},
        onContinueAsGuest: {}
    )
}
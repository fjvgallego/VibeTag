import SwiftUI

struct WelcomeView: View {
    var onRequestPermissions: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.quarternote.3")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
                .padding(.bottom, 20)
            
            Text("Welcome to VibeTag")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("To organize your library by vibes, we need access to your Apple Music library.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button(action: onRequestPermissions) {
                Text("Connect Music Library")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    WelcomeView(onRequestPermissions: {})
}

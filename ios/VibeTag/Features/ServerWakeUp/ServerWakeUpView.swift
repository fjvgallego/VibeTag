import SwiftUI

struct ServerWakeUpView: View {
    @Binding var isServerReady: Bool
    @State private var viewModel = ServerWakeUpViewModel()
    @State private var animateBackground = false

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
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

                VStack(spacing: 20) {
                    progressBar

                    Text(viewModel.currentPhrase)
                        .font(.nunito(.subheadline, weight: .medium))
                        .foregroundColor(.secondary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.4), value: viewModel.currentPhrase)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
            .safeAreaPadding()
        }
        .task {
            await viewModel.wakeUpServer()
        }
        .onChange(of: viewModel.isServerReady) { _, ready in
            if ready {
                // Brief delay to show 100% before transitioning
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isServerReady = true
                }
            }
        }
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 280, height: 8)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.appleMusicRed, .appleMusicRed.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 280 * viewModel.progress, height: 8)
                .animation(.easeOut(duration: 0.5), value: viewModel.progress)
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

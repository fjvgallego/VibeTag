import SwiftUI

@Observable
@MainActor
final class ServerWakeUpViewModel {
    var isServerReady = false
    var progress: Double = 0.0
    var currentPhrase: String

    private let phrases = [
        "Preparando tus vibes...",
        "Despertando el servidor...",
        "Asegurando los temazos...",
        "Afinando los algoritmos...",
        "Casi listo...",
        "Revisando novedades...",
        "Sincronizando datos...",
        "Un momento más..."
    ]

    private var phraseIndex = 0
    private var progressTimer: Timer?
    private var phraseTimer: Timer?
    private var startTime: Date?

    init() {
        currentPhrase = phrases[0]
    }

    func wakeUpServer() async {
        startTime = Date()
        startTimers()

        let url = URL(string: VTEnvironment.healthURL)!
        let session = URLSession.shared

        while !isServerReady {
            do {
                let (_, response) = try await session.data(from: url)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    isServerReady = true
                    stopTimers()
                    withAnimationOnMain {
                        self.progress = 1.0
                    }
                    return
                }
            } catch {
                // Server not ready yet — retry
            }

            try? await Task.sleep(for: .seconds(3))
        }
    }

    private func startTimers() {
        // Progress timer — ticks every 0.5s
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }

        // Phrase timer — cycles every 4s
        phraseTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cyclePhrase()
            }
        }
    }

    private func stopTimers() {
        progressTimer?.invalidate()
        progressTimer = nil
        phraseTimer?.invalidate()
        phraseTimer = nil
    }

    private func updateProgress() {
        guard let startTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        // Asymptotic curve: approaches 0.95 over ~50 seconds, then slows down
        let target = 0.95 * (1 - exp(-elapsed / 20.0))
        if progress < target {
            progress = target
        }
    }

    private func cyclePhrase() {
        phraseIndex = (phraseIndex + 1) % phrases.count
        currentPhrase = phrases[phraseIndex]
    }

    private func withAnimationOnMain(_ body: @escaping () -> Void) {
        withAnimation(.easeOut(duration: 0.3)) {
            body()
        }
    }
}

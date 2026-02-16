import Foundation
@testable import VibeTag

@MainActor
final class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool
    var onConnectionChange: ((Bool) -> Void)?

    init(isConnected: Bool = false) {
        self.isConnected = isConnected
    }

    func simulateConnectionChange(to connected: Bool) {
        isConnected = connected
        onConnectionChange?(connected)
    }
}

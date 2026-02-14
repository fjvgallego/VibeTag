import Foundation

@MainActor
protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
    var onConnectionChange: ((Bool) -> Void)? { get set }
}

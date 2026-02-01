import Foundation
import MusicKit

@MainActor
protocol MusicAuthRepository {
    func requestAuthorization() async -> MusicAuthorization.Status
    func getAuthorizationStatus() -> MusicAuthorization.Status
    func canPlayCatalogContent() async throws -> Bool
}

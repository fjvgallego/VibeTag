import Foundation
import MusicKit

@MainActor
class AppleMusicAuthRepositoryImpl: MusicAuthRepository {
    
    func requestAuthorization() async -> MusicAuthorization.Status {
        return await MusicAuthorization.request()
    }
    
    func getAuthorizationStatus() -> MusicAuthorization.Status {
        return MusicAuthorization.currentStatus
    }
    
    func canPlayCatalogContent() async throws -> Bool {
        return try await MusicSubscription.current.canPlayCatalogContent
    }
}
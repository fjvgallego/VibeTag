import Foundation
import MusicKit
import SwiftUI

@Observable
class RootViewModel {
    private var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined
    
    var isAuthorized: Bool {
        musicAuthorizationStatus == .authorized
    }
    
    init() {
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
    }
    
    func updateAuthorizationStatus() {
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
    }
    
    func requestMusicPermissions() {
        Task {
            let status = await MusicAuthorization.request()
            await MainActor.run {
                self.musicAuthorizationStatus = status
            }
        }
    }
}

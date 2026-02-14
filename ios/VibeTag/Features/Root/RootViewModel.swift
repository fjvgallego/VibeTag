import Foundation
import MusicKit
import SwiftUI

@MainActor
@Observable
class RootViewModel {
    private var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined
    var isGuest: Bool = false

    var isAuthorized: Bool {
        musicAuthorizationStatus == .authorized || isGuest
    }

    init() {
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
    }

    func updateAuthorizationStatus() {
        musicAuthorizationStatus = MusicAuthorization.currentStatus
    }

    func requestMusicPermissions() {
        Task {
            let status = await MusicAuthorization.request()
            musicAuthorizationStatus = status
        }
    }

    func continueAsGuest() {
        isGuest = true
    }
}

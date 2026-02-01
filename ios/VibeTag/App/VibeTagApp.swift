//
//  VibeTagApp.swift
//  VibeTag
//
//  Created by Francisco Javier Gallego Lahera on 25/1/26.
//

import SwiftUI
import SwiftData

@main
struct VibeTagApp: App {
    @State private var sessionManager: SessionManager
    
    init() {
        // Composition Root: Configure APIClient
        let tokenStorage = KeychainTokenStorage()
        APIClient.shared.setup(tokenStorage: tokenStorage)
        
        self._sessionManager = State(initialValue: SessionManager(tokenStorage: tokenStorage))
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionManager)
        }
        .modelContainer(for: [VTSong.self, Tag.self])
    }
}

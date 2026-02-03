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
    private let container: AppContainer
    private let modelContainer: ModelContainer
    
    init() {
        // SwiftData Container
        do {
            modelContainer = try ModelContainer(for: VTSong.self, Tag.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        // DI Container
        container = AppContainer(modelContext: modelContainer.mainContext)
        
        // Configure APIClient with the container's token storage
        APIClient.shared.setup(tokenStorage: container.tokenStorage)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
        .modelContainer(modelContainer)
    }
}
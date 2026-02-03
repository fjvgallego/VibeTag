//
//  VibeTagApp.swift
//  VibeTag
//
//  Created by Francisco Javier Gallego Lahera on 25/1/26.
//

import SwiftUI
import Sentry

import SwiftData

@main
struct VibeTagApp: App {
    private let container: AppContainer
    private let modelContainer: ModelContainer
    
    init() {
        SentrySDK.start { options in
            options.dsn = "https://b1fb94262b13332a526203b2fef0fa4e@o4510822413434880.ingest.de.sentry.io/4510822452297808"
            options.debug = true

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
             options.attachScreenshot = true // This adds a screenshot to the error events
             options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
            // Enable experimental logging features
            options.experimental.enableLogs = true
        }
        
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

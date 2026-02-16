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
            options.dsn = VTEnvironment.sentryDSN
            options.debug = VTEnvironment.isSentryDebugEnabled

            // Adds IP for users, cookies, and request data to error reports.
            // NOTE: Ensure this aligns with your privacy policy and user consent mechanisms
            // for GDPR/CCPA compliance. Consider making this configurable based on user consent.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = VTEnvironment.sentryProfilingSampleRate
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
            options.attachScreenshot = true // This adds a screenshot to the error events
            options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
            // Enable logging features
            options.enableLogs = true
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

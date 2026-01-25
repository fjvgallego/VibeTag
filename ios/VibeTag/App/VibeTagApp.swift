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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
            Tag.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

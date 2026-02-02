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
    @State private var syncEngine: VibeTagSyncEngine
    private let modelContainer: ModelContainer
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // SwiftData Container
        do {
            modelContainer = try ModelContainer(for: VTSong.self, Tag.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        // Composition Root: Configure APIClient
        let tokenStorage = KeychainTokenStorage()
        APIClient.shared.setup(tokenStorage: tokenStorage)
        
        let authRepository = VibeTagAuthRepositoryImpl()
        let localRepo = LocalSongStorageRepositoryImpl(modelContext: modelContainer.mainContext)
        let sessionManager = SessionManager(tokenStorage: tokenStorage, authRepository: authRepository)
        
        self._syncEngine = State(initialValue: VibeTagSyncEngine(localRepo: localRepo, sessionManager: sessionManager))
        self._sessionManager = State(initialValue: sessionManager)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionManager)
                .environment(syncEngine)
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await syncEngine.pullRemoteData()
                    await syncEngine.syncPendingChanges()
                }
            }
        }
    }
}
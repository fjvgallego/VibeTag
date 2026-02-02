import Foundation
import Observation

@Observable
@MainActor
class VibeTagSyncEngine: SyncEngine {
    private let localRepo: SongStorageRepository
    private let networkMonitor: NetworkMonitor
    private let sessionManager: SessionManager
    private var isPulling = false
    private var isPushing = false
    
    init(localRepo: SongStorageRepository, 
         sessionManager: SessionManager,
         networkMonitor: NetworkMonitor = .shared) {
        self.localRepo = localRepo
        self.sessionManager = sessionManager
        self.networkMonitor = networkMonitor
        
        setupObservation()
        
        // Sync on Launch
        Task {
            await pullRemoteData()
            await syncPendingChanges()
        }
    }
    
    private func setupObservation() {
        networkMonitor.onConnectionChange = { [weak self] isConnected in
            guard let self = self else { return }
            if isConnected {
                Task {
                    await self.pullRemoteData()
                    await self.syncPendingChanges()
                }
            }
        }
    }
    
    func pullRemoteData() async {
        guard !isPulling, networkMonitor.isConnected, sessionManager.isAuthenticated else { return }
        
        isPulling = true
        defer { isPulling = false }
        
        do {
            // 2. Fetch remote tags (Downstream Sync)
            let remoteLibrary: [SyncedSongDTO] = try await APIClient.shared.request(SongEndpoint.getSyncedSongs)
            try await localRepo.hydrateRemoteTags(remoteLibrary)
            print("Successfully pulled and hydrated remote tags.")
        } catch {
            print("Failed to pull remote data: \(error.localizedDescription)")
        }
    }
    
    func syncPendingChanges() async {
        guard !isPushing, networkMonitor.isConnected, sessionManager.isAuthenticated else { return }
        
        isPushing = true
        defer { isPushing = false }
        
        do {
            let pendingSongs = try await localRepo.fetchPendingUploads()
            
            for song in pendingSongs {
                let tagsToSync = song.tags.map { $0.name }.sorted()
                
                do {
                    let dto = UpdateSongDTO(tags: tagsToSync)
                    try await APIClient.shared.requestVoid(SongEndpoint.updateSong(id: song.id, dto: dto))
                    
                    // Check if tags changed during upload (Race Condition Fix)
                    let currentTags = song.tags.map { $0.name }.sorted()
                    if currentTags == tagsToSync {
                        try await localRepo.markAsSynced(songId: song.id)
                        print("Successfully synced song: \(song.title)")
                    } else {
                        print("Song \(song.title) changed during sync. Skipping markAsSynced.")
                    }
                } catch {
                    print("Failed to sync song \(song.id): \(error.localizedDescription)")
                    // Continue with next song
                }
            }
        } catch {
            print("Error fetching pending uploads: \(error.localizedDescription)")
        }
    }
}
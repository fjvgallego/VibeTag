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
    }
    
    private func setupObservation() {
        networkMonitor.onConnectionChange = { [weak self] isConnected in
            guard let self = self else { return }
            if isConnected {
                Task { [weak self] in
                    guard let self = self else { return }
                    do {
                        try await self.pullRemoteData()
                        await self.syncPendingChanges()
                    } catch {
                        print("Sync error on reconnection: \(error)")
                    }
                }
            }
        }
    }
    
    func pullRemoteData() async throws {
        guard !isPulling, networkMonitor.isConnected, sessionManager.isAuthenticated else { return }
        
        isPulling = true
        defer { isPulling = false }
        
        // 2. Fetch remote tags (Downstream Sync) with Pagination
        let limit = 100
        var page = 1
        var hasMoreData = true
        
        while hasMoreData {
            let remoteLibrary: [SyncedSongDTO] = try await APIClient.shared.request(SongEndpoint.getSyncedSongs(page: page, limit: limit))
            if !remoteLibrary.isEmpty {
                let syncInfo = remoteLibrary.map { song in
                    RemoteSongSyncInfo(
                        id: song.id,
                        appleMusicId: song.appleMusicId,
                        artworkUrl: song.artworkUrl,
                        tags: song.tags.map { RemoteTagSyncInfo(name: $0.name, type: $0.type) }
                    )
                }
                try await localRepo.hydrateRemoteTags(syncInfo)
            }
            
            if remoteLibrary.count < limit {
                hasMoreData = false
            } else {
                page += 1
            }
        }
        print("Successfully pulled and hydrated all remote tags.")
    }
    
    func syncPendingChanges() async {
        guard !isPushing, networkMonitor.isConnected, sessionManager.isAuthenticated else { return }
        
        isPushing = true
        defer { isPushing = false }
        
        do {
            let pendingSongs = try await localRepo.fetchPendingUploads()
            
            for song in pendingSongs {
                let tagsToSync = song.tags
                    .map { $0.name }
                    .sorted()
                
                do {
                    let dto = UpdateSongDTO(tags: tagsToSync, title: song.title, artist: song.artist, appleMusicId: song.appleMusicId, artworkUrl: song.artworkUrl)
                    try await APIClient.shared.requestVoid(SongEndpoint.updateSong(id: song.id, dto: dto))
                    
                    // Re-fetch to check if tags changed during upload (Race Condition Fix)
                    let currentTags = try localRepo.fetchSong(id: song.id)?.tags.map { $0.name }.sorted() ?? []
                    
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

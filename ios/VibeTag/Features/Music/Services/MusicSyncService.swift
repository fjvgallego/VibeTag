import Foundation
import MusicKit
import SwiftData

enum MusicSyncError: LocalizedError {
    case authorizationDenied
    case privacyAcknowledgementRequired
    case generic(Error)
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Music library access denied. Please enable it in Settings."
        case .privacyAcknowledgementRequired:
            return "⚠️ Setup Required: Please open the system 'Music' app once to accept the Welcome/Terms screen, then try again."
        case .generic(let error):
            return "Music Request Failed. (\(error.localizedDescription)). \n\nTip: Try opening the Music app to ensure your library is accessible."
        }
    }
}

@MainActor
class MusicSyncService {
    private let repository: MusicRepository
    private let storage: SongStorageRepository
    
    init(repository: MusicRepository, storage: SongStorageRepository) {
        self.repository = repository
        self.storage = storage
    }
    
    init(modelContext: ModelContext) {
        self.repository = AppleMusicRepository()
        self.storage = LocalSongStorageRepository(modelContext: modelContext)
    }
    
    func syncLibrary() async throws {
        var status = repository.getAuthorizationStatus()
        if status == .notDetermined {
            status = await repository.requestAuthorization()
        }
        
        guard status == .authorized else {
            throw MusicSyncError.authorizationDenied
        }
        
        do {
            if try await repository.canPlayCatalogContent() == false {
                 print("MusicSyncService: User cannot play catalog content (No Subscription).")
            }
            
            let remoteSongs = try await repository.fetchSongs(limit: 50)
            let remoteSongIDs = Set(remoteSongs.map { $0.id })
            
            let localSongs = try storage.fetchAllSongs()
            
            let songsToDelete = localSongs.filter { !remoteSongIDs.contains($0.id) }
            
            for song in songsToDelete {
                storage.deleteSong(song)
            }
            
            let localSongIDs = Set(localSongs.map { $0.id })
            
            for song in remoteSongs {
                if localSongIDs.contains(song.id) {
                    continue 
                }
                
                storage.saveSong(song)
            }
            
            try storage.saveChanges()
            
        } catch {
            throw mapError(error)
        }
    }
    
    private func mapError(_ error: Error) -> MusicSyncError {
        let rawError = String(describing: error)
        let localized = error.localizedDescription
        print("MusicSyncService: Request failed. RAW: \(rawError) | LOC: \(localized)")
        
        let combinedError = "\(rawError) \(localized)".lowercased()
        
        if combinedError.contains("privacy") || 
           combinedError.contains("acknowledgement") || 
           combinedError.contains("terms") || 
           combinedError.contains("agreement") {
            
            return .privacyAcknowledgementRequired
        }
        
        return .generic(error)
    }
}

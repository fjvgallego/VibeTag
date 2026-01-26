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
    private let provider: MusicLibraryProvider
    private let storage: SongPersistenceService
    
    init(provider: MusicLibraryProvider, storage: SongPersistenceService) {
        self.provider = provider
        self.storage = storage
    }
    
    init(modelContext: ModelContext) {
        self.provider = MusicKitProvider()
        self.storage = SwiftDataSongStorage(modelContext: modelContext)
    }
    
    func syncLibrary() async throws {
        var status = provider.getAuthorizationStatus()
        if status == .notDetermined {
            status = await provider.requestAuthorization()
        }
        
        guard status == .authorized else {
            throw MusicSyncError.authorizationDenied
        }
        
        do {
            if try await provider.canPlayCatalogContent() == false {
                 print("MusicSyncService: User cannot play catalog content (No Subscription).")
            }
            
            let remoteSongs = try await provider.fetchSongs(limit: 50)
            let remoteSongIDs = Set(remoteSongs.map { $0.id.rawValue })
            
            let localSongs = try storage.fetchAllSongs()
            
            let songsToDelete = localSongs.filter { !remoteSongIDs.contains($0.id) }
            
            for song in songsToDelete {
                storage.deleteSong(song)
            }
            
            let localSongIDs = Set(localSongs.map { $0.id })
            
            for song in remoteSongs {
                let songID = song.id.rawValue
                
                if localSongIDs.contains(songID) {
                    continue 
                }
                
                try await processNewSong(song)
            }
            
            try storage.saveChanges()
            
        } catch {
            throw mapError(error)
        }
    }
    
    private func processNewSong(_ song: Song) async throws {
        let artworkUrl = song.artwork?.url(width: 300, height: 300)?.absoluteString
        
        let newSong = VTSong(
            id: song.id.rawValue,
            title: song.title,
            artist: song.artistName,
            artworkUrl: artworkUrl,
            dateAdded: Date()
        )
        
        storage.saveSong(newSong)
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

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
            
            let songs = try await provider.fetchSongs(limit: 50)
            
            for song in songs {
                try await processSong(song)
            }
            
            try storage.saveChanges()
            
        } catch {
            throw mapError(error)
        }
    }
    
    private func processSong(_ song: Song) async throws {
        let songID = song.id.rawValue
        
        if try storage.songExists(id: songID) {
            return
        }
        
        let artworkUrl = song.artwork?.url(width: 300, height: 300)?.absoluteString
        
        let newSong = VTSong(
            id: songID,
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

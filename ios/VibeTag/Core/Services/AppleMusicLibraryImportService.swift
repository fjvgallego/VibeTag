import Foundation
import MusicKit
import SwiftData
import MediaPlayer

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
class AppleMusicLibraryImportService: LibraryImportSyncService {
    private let musicAuthRepository: MusicAuthRepository
    private let songRepository: SongRepository
    private let storage: SongStorageRepository
    
    init(authRepository: MusicAuthRepository, songRepository: SongRepository, storage: SongStorageRepository) {
        self.musicAuthRepository = authRepository
        self.songRepository = songRepository
        self.storage = storage
    }
    
    init(modelContext: ModelContext) {
        self.musicAuthRepository = AppleMusicAuthRepositoryImpl()
        self.songRepository = AppleMusicSongRepositoryImpl()
        self.storage = LocalSongStorageRepositoryImpl(modelContext: modelContext)
    }
    
    func syncLibrary() async throws {
        var status = musicAuthRepository.getAuthorizationStatus()
        if status == .notDetermined {
            status = await musicAuthRepository.requestAuthorization()
        }
        
        guard status == .authorized else {
            throw MusicSyncError.authorizationDenied
        }
        
        do {
            if try await musicAuthRepository.canPlayCatalogContent() == false {
                 print("MusicSyncService: User cannot play catalog content (No Subscription).")
            }
            
            let fetchLimit = 300
            let remoteSongs = try await songRepository.fetchSongs(limit: fetchLimit)

            let localSongs = try storage.fetchAllSongs()
            let remoteSongIDs = Set(remoteSongs.map { $0.id })

            for song in remoteSongs {
                if let existing = localSongs.first(where: { $0.id == song.id }) {
                    // Update missing metadata for existing songs
                    var changed = false
                    if existing.artworkUrl == nil && song.artworkUrl != nil {
                        existing.artworkUrl = song.artworkUrl
                        changed = true
                    }
                    if existing.appleMusicId == nil && song.appleMusicId != nil {
                        existing.appleMusicId = song.appleMusicId
                        changed = true
                    }

                    if changed {
                        existing.syncStatus = .pendingUpload
                    }
                } else {
                    // New song found
                    song.syncStatus = .pendingUpload
                    storage.saveSong(song)
                }
            }

            // Remove songs deleted from Apple Music.
            // Only safe when we fetched the full library (count < limit),
            // otherwise songs beyond the limit would be incorrectly deleted.
            if remoteSongs.count < fetchLimit {
                for localSong in localSongs where !remoteSongIDs.contains(localSong.id) {
                    storage.deleteSong(localSong)
                }
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

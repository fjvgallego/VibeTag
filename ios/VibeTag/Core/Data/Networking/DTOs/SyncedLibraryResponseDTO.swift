import Foundation

struct SyncedTagDTO: Codable {
    let name: String
    let type: String // "SYSTEM" or "USER"
    let color: String?
}

struct SyncedSongDTO: Codable {
    let id: String
    let appleMusicId: String?
    let artworkUrl: String?
    let tags: [SyncedTagDTO]
}

typealias SyncedLibraryResponseDTO = [SyncedSongDTO]

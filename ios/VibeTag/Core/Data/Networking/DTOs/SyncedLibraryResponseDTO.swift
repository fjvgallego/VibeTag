import Foundation

struct SyncedTagDTO: Codable {
    let name: String
    let type: String // "SYSTEM" or "USER"
}

struct SyncedSongDTO: Codable {
    let id: String
    let tags: [SyncedTagDTO]
}

typealias SyncedLibraryResponseDTO = [SyncedSongDTO]

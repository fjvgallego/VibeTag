import Foundation

struct SyncedSongDTO: Codable {
    let id: String
    let tags: [String]
}

typealias SyncedLibraryResponseDTO = [SyncedSongDTO]

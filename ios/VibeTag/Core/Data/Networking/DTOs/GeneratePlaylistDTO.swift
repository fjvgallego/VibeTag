import Foundation

struct GeneratePlaylistRequestDTO: Encodable {
    let prompt: String
}

struct GeneratePlaylistResponseDTO: Decodable {
    struct SongDTO: Decodable, Identifiable {
        let id: String
        let title: String
        let artist: String
        // Backend sends tags as [String], mapped from VibeTag.name
        let tags: [String] 
    }
    
    let playlistTitle: String
    let description: String
    let usedTags: [String]
    let songs: [SongDTO]
}

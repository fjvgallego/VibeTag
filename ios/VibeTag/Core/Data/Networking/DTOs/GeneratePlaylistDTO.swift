import Foundation

struct GeneratePlaylistRequestDTO: Encodable {
    let prompt: String
}

struct GeneratePlaylistResponseDTO: Decodable {
    struct PlaylistTagDTO: Decodable {
        let name: String
        let type: String
    }

    struct SongDTO: Decodable, Identifiable {
        let id: String
        let title: String
        let artist: String
        let appleMusicId: String?
        let artworkUrl: String?
        let tags: [PlaylistTagDTO] 
    }
    
    let playlistTitle: String
    let description: String
    let usedTags: [String]
    let songs: [SongDTO]
}

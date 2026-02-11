import Foundation

struct AnalyzeRequestDTO: Encodable {
    let songId: String?
    let appleMusicId: String?
    let artist: String
    let title: String
    let artworkUrl: String?
}

struct BatchAnalyzeRequestDTO: Encodable {
    struct SongInput: Encodable {
        let songId: String
        let appleMusicId: String?
        let title: String
        let artist: String
        let album: String?
        let genre: String?
        let artworkUrl: String?
    }
    let songs: [SongInput]
}

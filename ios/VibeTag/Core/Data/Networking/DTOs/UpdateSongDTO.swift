import Foundation

struct UpdateSongDTO: Encodable {
    let tags: [String]
    let title: String
    let artist: String
    let appleMusicId: String?
    let artworkUrl: String?
}

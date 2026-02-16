import Foundation

struct TagUpdateDTO: Encodable {
    let name: String
    let color: String?
}

struct UpdateSongDTO: Encodable {
    let tags: [TagUpdateDTO]
    let title: String
    let artist: String
    let appleMusicId: String?
    let artworkUrl: String?
}

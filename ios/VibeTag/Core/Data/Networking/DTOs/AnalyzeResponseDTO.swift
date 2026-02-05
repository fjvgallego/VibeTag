import Foundation

struct TagDTO: Decodable {
    let name: String
    let description: String?
}

struct AnalyzeResponseDTO: Decodable {
    let songId: String
    let tags: [TagDTO]
}

struct BatchAnalyzeResponseDTO: Decodable {
    struct SongResult: Decodable {
        let songId: String?
        let title: String
        let tags: [TagDTO]
    }
    let results: [SongResult]
}

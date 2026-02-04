import Foundation

struct AnalyzeResponseDTO: Decodable {
    let tags: [String]
    
    func toDomain() -> [String] {
        return tags
    }
}

struct BatchAnalyzeResponseDTO: Decodable {
    struct SongResult: Decodable {
        let songId: String?
        let title: String
        let tags: [String]
    }
    let results: [SongResult]
}

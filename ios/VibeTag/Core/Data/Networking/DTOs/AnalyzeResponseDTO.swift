import Foundation

struct AnalyzeResponseDTO: Decodable {
    let tags: [String]
    
    func toDomain() -> [String] {
        return tags
    }
}

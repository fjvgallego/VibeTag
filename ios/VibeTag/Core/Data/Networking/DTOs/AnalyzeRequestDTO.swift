import Foundation

struct AnalyzeRequestDTO: Encodable {
    let songId: String?
    let artist: String
    let title: String
}

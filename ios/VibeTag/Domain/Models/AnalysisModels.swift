import Foundation

struct AnalyzedTag {
    let name: String
    let description: String?
}

struct SongAnalysisResult {
    let songId: String
    let tags: [AnalyzedTag]
}

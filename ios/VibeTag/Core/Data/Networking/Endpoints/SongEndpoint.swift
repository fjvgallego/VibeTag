import Foundation

enum SongEndpoint: Endpoint {
    case analyze(artist: String, title: String)
    
    var path: String {
        switch self {
        case .analyze:
            return "/analyze/song"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .analyze:
            return .POST
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var body: Encodable? {
        switch self {
        case .analyze(let artist, let title):
            return AnalyzeRequestDTO(artist: artist, title: title)
        }
    }
}

import Foundation

enum PlaylistEndpoint: Endpoint {
    case generate(prompt: String)
    
    var path: String {
        switch self {
        case .generate:
            return "/playlists/generate"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .generate:
            return .POST
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var body: Encodable? {
        switch self {
        case .generate(let prompt):
            return GeneratePlaylistRequestDTO(prompt: prompt)
        }
    }
}

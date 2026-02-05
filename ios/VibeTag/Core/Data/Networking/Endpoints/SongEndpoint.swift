import Foundation

enum SongEndpoint: Endpoint {
    case analyze(id: String?, artist: String, title: String)
    case analyzeBatch(dto: BatchAnalyzeRequestDTO)
    case updateSong(id: String, dto: UpdateSongDTO)
    case getSyncedSongs(page: Int, limit: Int)
    
    var path: String {
        switch self {
        case .analyze:
            return "/analyze/song"
        case .analyzeBatch:
            return "/analyze/batch"
        case .updateSong(let id, _):
            return "/songs/\(id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id)"
        case .getSyncedSongs:
            return "/songs/synced"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .analyze, .analyzeBatch:
            return .POST
        case .updateSong:
            return .PATCH
        case .getSyncedSongs:
            return .GET
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var body: Encodable? {
        switch self {
        case .analyze(let id, let artist, let title):
            return AnalyzeRequestDTO(songId: id, artist: artist, title: title)
        case .analyzeBatch(let dto):
            return dto
        case .updateSong(_, let dto):
            return dto
        case .getSyncedSongs:
            return nil
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getSyncedSongs(let page, let limit):
            return [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        default:
            return nil
        }
    }
}

import Foundation

enum SongEndpoint: Endpoint {
    case analyze(id: String?, artist: String, title: String)
    case updateSong(id: String, dto: UpdateSongDTO)
    case getSyncedSongs
    
    var path: String {
        switch self {
        case .analyze:
            return "/analyze/song"
        case .updateSong(let id, _):
            return "/songs/\(id)"
        case .getSyncedSongs:
            return "/songs/synced"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .analyze:
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
        case .updateSong(_, let dto):
            return dto
        case .getSyncedSongs:
            return nil
        }
    }
}

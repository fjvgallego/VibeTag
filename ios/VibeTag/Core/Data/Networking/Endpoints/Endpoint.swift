import Foundation

enum HTTPMethod: String {
    case GET
    case POST
    case DELETE
    case PATCH
}

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Encodable? { get }
    var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {
    var queryItems: [URLQueryItem]? { return nil }
}

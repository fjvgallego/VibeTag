import Foundation

enum HTTPMethod: String {
    case GET
    case POST
    case DELETE
}

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Encodable? { get }
}

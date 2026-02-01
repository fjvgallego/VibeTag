import Foundation

enum HTTPMethod: String {
    case GET
    case POST
}

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Encodable? { get }
}

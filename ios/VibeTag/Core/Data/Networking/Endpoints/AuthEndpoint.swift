import Foundation

enum AuthEndpoint: Endpoint {
    case login(request: Encodable)
    
    var path: String {
        switch self {
        case .login:
            return "/auth/apple"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login:
            return .POST
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .login:
            return ["Content-Type": "application/json"]
        }
    }
    
    var body: Encodable? {
        switch self {
        case .login(let request):
            return request
        }
    }
}

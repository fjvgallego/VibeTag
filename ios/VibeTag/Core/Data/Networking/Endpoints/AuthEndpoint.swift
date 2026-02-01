import Foundation

enum AuthEndpoint: Endpoint {
    case login(request: Encodable)
    case deleteAccount
    
    var path: String {
        switch self {
        case .login:
            return "/auth/apple"
        case .deleteAccount:
            return "/auth/me"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login:
            return .POST
        case .deleteAccount:
            return .DELETE
        }
    }
    
    var headers: [String: String]? {
        return nil
    }
    
    var body: Encodable? {
        switch self {
        case .login(let request):
            return request
        case .deleteAccount:
            return nil
        }
    }
}

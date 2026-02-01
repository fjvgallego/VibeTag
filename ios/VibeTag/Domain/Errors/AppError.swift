import Foundation

enum AppError: Error, LocalizedError {
    case networkError(original: Error)
    case serverError(statusCode: Int)
    case unauthorized
    case decodingError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .networkError(let original):
            return "Network error: \(original.localizedDescription)"
        case .serverError(let statusCode):
            return "Server returned an error. Status code: \(statusCode)"
        case .unauthorized:
            return "Session expired or invalid credentials."
        case .decodingError:
            return "Failed to process server response."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

import Foundation

enum AppError: Error, LocalizedError {
    case networkError(original: Error)
    case serverError(statusCode: Int)
    case unauthorized
    case decodingError(original: Error)
    case songNotFound
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .networkError(let original):
            return "Network error: \(original.localizedDescription)"
        case .serverError(let statusCode):
            return "Server returned an error. Status code: \(statusCode)"
        case .unauthorized:
            return "Session expired or invalid credentials."
        case .decodingError(let original):
            return "Failed to process server response: \(original.localizedDescription)"
        case .songNotFound:
            return "The requested song could not be found."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

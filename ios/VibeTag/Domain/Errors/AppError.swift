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
        case .networkError:
            return "Error de conexión. Comprueba tu conexión a internet e inténtalo de nuevo."
        case .serverError(let statusCode):
            return "Error del servidor (código \(statusCode)). Inténtalo de nuevo más tarde."
        case .unauthorized:
            return "Sesión expirada o credenciales inválidas. Inicia sesión de nuevo."
        case .decodingError:
            return "No se pudo procesar la respuesta del servidor."
        case .songNotFound:
            return "No se encontró la canción solicitada."
        case .unknown:
            return "Ha ocurrido un error inesperado."
        }
    }
}

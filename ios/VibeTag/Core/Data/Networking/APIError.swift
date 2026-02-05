//
//  APIError.swift
//  VibeTag
//
//  Created by Francisco Javier Gallego Lahera on 1/2/26.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(original: Error)
    case unknown
    
    var toAppError: AppError {
        switch self {
        case .httpError(let statusCode):
            if statusCode == 401 {
                return AppError.unauthorized
            } else {
                return AppError.serverError(statusCode: statusCode)
            }
        case .decodingError(let original):
            return AppError.decodingError(original: original)
        case .invalidURL:
            return AppError.unknown
        case .unknown:
            return AppError.unknown
        }
    }
}

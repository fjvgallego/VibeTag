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
    case decodingError
    case unknown
    
    var toAppError: AppError {
        switch self {
        case .httpError(let statusCode):
            if statusCode == 401 {
                AppError.unauthorized
            } else {
                AppError.serverError(statusCode: statusCode)
            }
        case .decodingError:
            AppError.decodingError
        case .invalidURL:
            AppError.unknown
        case .unknown:
            AppError.unknown
        }
    }
}

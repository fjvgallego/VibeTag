import Foundation
@testable import VibeTag

final class MockAPIClient: APIClientProtocol {

    // MARK: - request<T>

    /// Each element is consumed in order, one per call.
    var requestResults: [Result<Any, Error>] = []
    var requestCallCount = 0
    var requestReceivedEndpoints: [any Endpoint] = []

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        requestCallCount += 1
        requestReceivedEndpoints.append(endpoint)
        guard !requestResults.isEmpty else {
            throw APIError.unknown
        }
        let result = requestResults.removeFirst()
        switch result {
        case .success(let value):
            guard let typed = value as? T else {
                throw APIError.unknown
            }
            return typed
        case .failure(let error):
            throw error
        }
    }

    // MARK: - requestVoid

    var requestVoidCallCount = 0
    var requestVoidReceivedEndpoints: [any Endpoint] = []
    /// Each element is consumed in order; nil means success.
    var requestVoidResults: [Error?] = []

    func requestVoid(_ endpoint: Endpoint) async throws {
        requestVoidCallCount += 1
        requestVoidReceivedEndpoints.append(endpoint)
        guard !requestVoidResults.isEmpty else { return }
        if let error = requestVoidResults.removeFirst() {
            throw error
        }
    }
}

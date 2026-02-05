import Foundation

final class APIClient {
    static let shared = APIClient()
    
    // NOTE: This needs to be the local IP for physical devices.
    // localhost works for Simulator.
    private let baseURL = VTEnvironment.baseURL
    private var tokenStorage: TokenStorage?
    
    private init() {}
    
    func setup(tokenStorage: TokenStorage) {
        self.tokenStorage = tokenStorage
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.path += endpoint.path
        
        if let queryItems = endpoint.queryItems {
            components?.queryItems = queryItems
        }
        
        guard let finalURL = components?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        
        // Default Content-Type
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Authorization header if token is available
        let token = tokenStorage?.getToken()
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = endpoint.body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(original: error)
        }
    }
    
    func requestVoid(_ endpoint: Endpoint) async throws {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.path += endpoint.path
        
        if let queryItems = endpoint.queryItems {
            components?.queryItems = queryItems
        }
        
        guard let finalURL = components?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        
        // Default Content-Type
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Authorization header if token is available
        let token = tokenStorage?.getToken()
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = endpoint.body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

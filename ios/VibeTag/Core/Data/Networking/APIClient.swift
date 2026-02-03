import Foundation

class APIClient {
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
        guard var components = URLComponents(string: "\(baseURL)\(endpoint.path)") else {
            throw APIError.invalidURL
        }
        
        if let queryItems = endpoint.queryItems {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Default Content-Type
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Authorization header if token is available
        if let token = tokenStorage?.getToken() {
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
            throw APIError.decodingError
        }
    }
    
    func requestVoid(_ endpoint: Endpoint) async throws {
        guard var components = URLComponents(string: "\(baseURL)\(endpoint.path)") else {
            throw APIError.invalidURL
        }
        
        if let queryItems = endpoint.queryItems {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Default Content-Type
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Authorization header if token is available
        if let token = tokenStorage?.getToken() {
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
    
    /// Sends a simple request to the root to trigger Local Network permissions on iOS 14+
    func ping() {
        guard let url = URL(string: baseURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        Task {
            do {
                let _ = try await URLSession.shared.data(for: request)
                // Success - permission granted or network available
            } catch {
                // Ignore errors - we just wanted to trigger the permission prompt
                print("Ping failed (expected during first launch if permission pending): \(error)")
            }
        }
    }
}
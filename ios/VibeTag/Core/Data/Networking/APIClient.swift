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
        guard let url = URL(string: "\(baseURL)\(endpoint.path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
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
            request.httpBody = try JSONEncoder().encode(body)
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
        guard let url = URL(string: "\(baseURL)\(endpoint.path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
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
            request.httpBody = try JSONEncoder().encode(body)
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

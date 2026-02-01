import Foundation

enum VTEnvironment {
    enum Configuration {
        case debug
        case release
    }
    
    static var current: Configuration {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
    
    static var baseURL: String {
        switch current {
        case .debug:
            // Localhost for Simulator
//            return "http://localhost:3000/api/v1"
            // Use your machine's IP address for physical device testing
            return "http://192.168.1.245:3000/api/v1"
        case .release:
            // Replace with your actual production URL
            return "https://vibetag-backend.onrender.com/api/v1"
        }
    }
}

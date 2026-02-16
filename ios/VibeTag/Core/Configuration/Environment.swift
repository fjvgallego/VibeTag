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
            return "http://192.168.1.245:3000/api/v1"
            // Localhost for Simulator
//           return "http://localhost:3000/api/v1"
        case .release:
            // Replace with your actual production URL
            return "https://vibetag-backend.onrender.com/api/v1"
        }
    }

    static var healthURL: String {
        switch current {
        case .debug:
            return "http://192.168.1.245:3000/health"
        case .release:
            return "https://vibetag-backend.onrender.com/health"
        }
    }

    static var sentryDSN: String {
        return "https://b1fb94262b13332a526203b2fef0fa4e@o4510822413434880.ingest.de.sentry.io/4510822452297808"
    }

    static var isSentryDebugEnabled: Bool {
        return current == .debug
    }

    static var sentryTracesSampleRate: Double {
        return current == .debug ? 1.0 : 0.1
    }

    static var sentryProfilingSampleRate: Float {
        return current == .debug ? 1.0 : 0.1
    }
}

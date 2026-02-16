import SwiftUI

enum AppRoute: Hashable {
    case songDetail(songID: String)
    case tagDetail(tagID: UUID)
    case generatePlaylist(prompt: String)
}

@Observable
class AppRouter {
    var path: [AppRoute] = []
    
    func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func reset() {
        path = []
    }
}
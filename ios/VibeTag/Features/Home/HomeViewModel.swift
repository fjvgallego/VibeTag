import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class HomeViewModel {
    var searchText: String = ""
    var isSyncing: Bool = false
    var errorMessage: String?
    
    private let queryExpander: SearchQueryExpanding = SearchQueryExpander()
    
    var searchTokens: [String] {
        queryExpander.expandSearchTerm(searchText)
    }
    
    func syncLibrary(modelContext: ModelContext) async {
        isSyncing = true
        errorMessage = nil
        
        do {
            let service = MusicSyncService(modelContext: modelContext)
            try await service.syncLibrary()
        } catch {
            errorMessage = "Failed to sync library: \(error.localizedDescription)"
        }
        
        isSyncing = false
    }
}

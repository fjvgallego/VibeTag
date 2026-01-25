import Foundation
import SwiftData
import SwiftUI

@Observable
class HomeViewModel {
    var searchText: String = ""
    
    // Future logic for filtering or fetching data will go here.
    // Since we use @Query in the View for SwiftData, the ViewModel handles 
    // UI state (like search text, sheet presentation) and Service calls.
    
    init() {}
}

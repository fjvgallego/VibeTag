import Foundation

enum SyncStatus: Int, Codable {
    case synced = 0         // Data matches Backend
    case pendingUpload = 1  // Modified locally, needs upload
    case pendingDelete = 2  // Deleted locally, needs backend delete
}

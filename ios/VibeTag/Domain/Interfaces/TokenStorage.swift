import Foundation

protocol TokenStorage {
    func save(token: String) throws
    func getToken() -> String?
    func deleteToken() throws
}

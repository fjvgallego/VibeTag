import Foundation
import Security

class KeychainTokenStorage: TokenStorage {
    
    private let service = "com.vibetag.auth"
    private let account = "authToken"
    
    func save(token: String) throws {
        let data = Data(token.utf8)
        
        // Create the search query for the item
        let searchQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // Delete any existing item
        SecItemDelete(searchQuery as CFDictionary)
        
        // Add the data to the query for addition
        var addQuery = searchQuery
        addQuery[kSecValueData as String] = data
        
        // Add the new item
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw TokenStorageError.saveFailed(status: status)
        }
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func deleteToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStorageError.deleteFailed(status: status)
        }
    }
}

enum TokenStorageError: Error {
    case saveFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
}

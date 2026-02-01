import Foundation

struct UserDTO: Codable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
}

extension UserDTO {
    func toDomain() -> User {
        return User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName
        )
    }
}

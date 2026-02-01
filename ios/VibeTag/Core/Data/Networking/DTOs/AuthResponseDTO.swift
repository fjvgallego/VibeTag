import Foundation

struct AuthResponseDTO: Codable {
    let token: String
    let user: UserDTO
}

extension AuthResponseDTO {
    func toDomain() -> AuthResponse {
        return AuthResponse(
            token: token,
            user: user.toDomain()
        )
    }
}

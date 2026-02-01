export interface TokenPayload {
  userId: string;
  email: string | null;
}

export interface ITokenService {
  /**
   * Generates a token signed with our secret key.
   * @param payload Data to be stored inside the token (e.g., user ID)
   * @returns The token string (e.g., "eyJhbG...")
   */
  generate(payload: TokenPayload): string;

  /**
   * Verifies if a token is valid and returns the data.
   * @param token The token string
   */
  verify(token: string): TokenPayload | null;
}

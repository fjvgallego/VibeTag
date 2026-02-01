export interface AppleUserData {
  appleId: string;
  email?: string;
}

export interface IAuthProvider {
  verifyAppleToken(identityToken: string): Promise<AppleUserData>;
}

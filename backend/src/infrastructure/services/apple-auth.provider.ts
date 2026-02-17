import appleSignin from 'apple-signin-auth';
import { AppleUserData, IAuthProvider } from '../../application/ports/auth-provider';

export class AppleAuthProvider implements IAuthProvider {
  constructor(private readonly appleClientId: string) {}

  async verifyAppleToken(identityToken: string): Promise<AppleUserData> {
    try {
      const { sub, email } = await appleSignin.verifyIdToken(identityToken, {
        audience: this.appleClientId,
        ignoreExpiration: false,
      });

      return {
        appleId: sub,
        email: email,
      };
    } catch (error) {
      console.error('Error verifying Apple token:', error);
      throw new Error('Invalid Apple Identity Token');
    }
  }
}

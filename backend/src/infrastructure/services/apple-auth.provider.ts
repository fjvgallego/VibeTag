import appleSignin from 'apple-signin-auth';
import { AppleUserData, IAuthProvider } from '../../application/ports/auth-provider';
import { config } from '../../composition/config/config';

export class AppleAuthProvider implements IAuthProvider {
  async verifyAppleToken(identityToken: string): Promise<AppleUserData> {
    try {
      const { sub, email } = await appleSignin.verifyIdToken(identityToken, {
        audience: config.APPLE_CLIENT_ID,
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

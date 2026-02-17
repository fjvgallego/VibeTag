import jwt from 'jsonwebtoken';
import { ITokenService, TokenPayload } from '../../application/ports/token-service';

export class JwtTokenService implements ITokenService {
  private readonly expiresIn: jwt.SignOptions['expiresIn'];

  constructor(private readonly secret: string) {
    if (!secret) {
      throw new Error('JWT_SECRET must be configured');
    }
    // Session duration. For mobile it is usually long (e.g. 30 days)
    this.expiresIn = '30d';
  }

  generate(payload: TokenPayload): string {
    return jwt.sign(payload, this.secret, {
      expiresIn: this.expiresIn,
      algorithm: 'HS256',
    });
  }

  verify(token: string): TokenPayload | null {
    try {
      return jwt.verify(token, this.secret, { algorithms: ['HS256'] }) as TokenPayload;
    } catch {
      // If the token has expired or the signature is wrong, we return null
      return null;
    }
  }
}

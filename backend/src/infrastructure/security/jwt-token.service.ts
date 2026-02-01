import jwt from 'jsonwebtoken';
import { ITokenService, TokenPayload } from '../../application/ports/token-service';
import { config } from '../../composition/config/config';

export class JwtTokenService implements ITokenService {
  private readonly secret: string;
  private readonly expiresIn: jwt.SignOptions['expiresIn'];

  constructor() {
    this.secret = config.JWT_SECRET;
    // Session duration. For mobile it is usually long (e.g. 30 days)
    this.expiresIn = '30d';
  }

  generate(payload: TokenPayload): string {
    return jwt.sign(payload, this.secret, {
      expiresIn: this.expiresIn,
    });
  }

  verify(token: string): TokenPayload | null {
    try {
      return jwt.verify(token, this.secret) as TokenPayload;
    } catch {
      // If the token has expired or the signature is wrong, we return null
      return null;
    }
  }
}

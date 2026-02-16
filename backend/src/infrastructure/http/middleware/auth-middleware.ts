import { Request, Response, NextFunction } from 'express';
import { ITokenService } from '../../../application/ports/token-service';

export function createVerifyToken(tokenService: ITokenService) {
  return function verifyToken(req: Request, res: Response, next: NextFunction) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer <token>

    if (!token) {
      res.status(401).json({ error: 'Unauthorized: No token provided' });
      return;
    }

    const decoded = tokenService.verify(token);

    if (!decoded) {
      res.status(401).json({ error: 'Unauthorized: Invalid token' });
      return;
    }

    req.user = decoded;
    next();
  };
}

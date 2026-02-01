import { Request, Response } from 'express';
import { LoginWithAppleUseCase } from '../../../application/use-cases/auth/login-with-apple.use-case';
import { AuthError, ValidationError } from '../../../domain/errors/app-error';

export class AuthController {
  constructor(private readonly loginWithAppleUseCase: LoginWithAppleUseCase) {}

  public async loginWithApple(req: Request, res: Response): Promise<Response> {
    try {
      const { identityToken, firstName, lastName } = req.body || {};

      if (!identityToken) {
        return res.status(400).json({ message: 'Missing identityToken' });
      }

      const result = await this.loginWithAppleUseCase.execute({
        identityToken,
        firstName,
        lastName,
      });

      if (result.success) {
        const { user, token } = result.getValue();

        return res.json({
          user,
          token,
        });
      }

      const error = result.error;
      if (error instanceof ValidationError) {
        return res.status(400).json({ message: error.message });
      }
      if (error instanceof AuthError) {
        return res.status(401).json({ message: error.message });
      }

      return res.status(500).json({ message: 'Internal server error' });
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: 'Unexpected error' });
    }
  }
}

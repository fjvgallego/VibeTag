import { Request, Response } from 'express';
import { LoginWithAppleUseCase } from '../../../application/use-cases/auth/login-with-apple.use-case';
import { DeleteAccountUseCase } from '../../../application/use-cases/auth/delete-account.use-case';
import { AuthError, UserNotFoundError, ValidationError } from '../../../domain/errors/app-error';

export class AuthController {
  constructor(
    private readonly loginWithAppleUseCase: LoginWithAppleUseCase,
    private readonly deleteAccountUseCase: DeleteAccountUseCase,
  ) {}

  public async loginWithApple(req: Request, res: Response): Promise<Response> {
    try {
      const { identityToken, firstName, lastName, email } = req.body || {};

      if (!identityToken) {
        return res.status(400).json({ message: 'Missing identityToken' });
      }

      const result = await this.loginWithAppleUseCase.execute({
        identityToken,
        firstName,
        lastName,
        email,
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

  public async deleteAccount(req: Request, res: Response): Promise<Response> {
    try {
      const userId = req.user?.userId;

      if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const result = await this.deleteAccountUseCase.execute({ userId });

      if (result.success) {
        return res.status(200).send();
      }

      const error = result.error;
      if (error instanceof ValidationError) {
        return res.status(400).json({ message: error.message });
      }
      if (error instanceof UserNotFoundError) {
        return res.status(404).json({ message: error.message });
      }

      return res.status(500).json({ message: 'Internal server error' });
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: 'Unexpected error' });
    }
  }
}

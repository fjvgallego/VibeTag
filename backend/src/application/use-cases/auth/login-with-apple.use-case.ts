import { UseCase } from '../use-case.interface';
import { Result } from '../../../shared/result';
import { AppError, AuthError } from '../../../domain/errors/app-error';
import { UserRepository } from '../../ports/user.repository';
import { IAuthProvider } from '../../ports/auth-provider';
import { ITokenService } from '../../ports/token-service';
import {
  LoginWithAppleRequestDTO,
  LoginWithAppleResponseDTO,
} from '../../dtos/login-with-apple.dto';
import { User } from '../../../domain/entities/user';
import { AppleId } from '../../../domain/value-objects/ids/apple-id.vo';
import { Email } from '../../../domain/value-objects/email.vo';

export class LoginWithAppleUseCase implements UseCase<
  LoginWithAppleRequestDTO,
  LoginWithAppleResponseDTO
> {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly authProvider: IAuthProvider,
    private readonly tokenService: ITokenService,
  ) {}

  async execute(
    request: LoginWithAppleRequestDTO,
  ): Promise<Result<LoginWithAppleResponseDTO, AppError>> {
    try {
      const appleUserData = await this.authProvider.verifyAppleToken(request.identityToken);
      const appleIdResult = AppleId.create(appleUserData.appleId);

      let email: Email | null = null;
      if (appleUserData.email) {
        email = Email.create(appleUserData.email);
      } else if (request.email) {
        email = Email.create(request.email);
      }

      const userCandidate = User.create(
        email,
        request.firstName || null,
        request.lastName || null,
        appleIdResult,
      );

      const user = await this.userRepository.upsertByAppleId(userCandidate);

      const token = this.tokenService.generate({
        userId: user.id.value,
        email: user.email?.value ?? null,
      });

      return Result.ok({
        user: {
          id: user.id.value,
          email: user.email?.value ?? null,
          firstName: user.firstName,
          lastName: user.lastName,
        },
        token,
      });
    } catch (error) {
      if (error instanceof AppError) {
        return Result.fail(error);
      }
      return Result.fail(
        new AuthError(error instanceof Error ? error.message : 'Unknown error during Apple login'),
      );
    }
  }
}

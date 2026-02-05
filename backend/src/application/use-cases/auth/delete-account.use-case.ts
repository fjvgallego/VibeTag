import { UserRepository } from '../../ports/user.repository';
import { UseCase } from '../use-case.interface';
import { Result } from '../../../shared/result';
import { AppError, UseCaseError, UserNotFoundError } from '../../../domain/errors/app-error';
import { UserId } from '../../../domain/value-objects/ids/user-id.vo';

interface DeleteAccountRequest {
  userId: string;
}

export class DeleteAccountUseCase implements UseCase<DeleteAccountRequest, void> {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(request: DeleteAccountRequest): Promise<Result<void, AppError>> {
    try {
      const userId = UserId.create(request.userId);
      const user = await this.userRepository.findById(userId);

      if (!user) {
        return Result.fail(new UserNotFoundError(`User with id ${request.userId} not found`));
      }

      await this.userRepository.delete(userId);
      return Result.ok<void, AppError>(undefined as unknown as void);
    } catch (error) {
      if (error instanceof AppError) {
        return Result.fail(error);
      }
      return Result.fail(new UseCaseError('Failed to delete account', { cause: error as Error }));
    }
  }
}

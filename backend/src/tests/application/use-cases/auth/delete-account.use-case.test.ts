import { describe, it, expect, vi, beforeEach } from 'vitest';
import { DeleteAccountUseCase } from '../../../../application/use-cases/auth/delete-account.use-case';
import { UserRepository } from '../../../../application/ports/user.repository';
import { User } from '../../../../domain/entities/user';
import { Email } from '../../../../domain/value-objects/email.vo';
import { AppleId } from '../../../../domain/value-objects/ids/apple-id.vo';
import { UserId } from '../../../../domain/value-objects/ids/user-id.vo';
import { UserNotFoundError, UseCaseError } from '../../../../domain/errors/app-error';

describe('DeleteAccountUseCase', () => {
  let useCase: DeleteAccountUseCase;
  let mockUserRepository: UserRepository;

  beforeEach(() => {
    mockUserRepository = {
      findByAppleId: vi.fn(),
      save: vi.fn(),
      findById: vi.fn(),
      upsertByAppleId: vi.fn(),
      delete: vi.fn(),
    };
    useCase = new DeleteAccountUseCase(mockUserRepository);
  });

  it('should delete user when user exists', async () => {
    const user = User.create(
      Email.create('john@example.com'),
      'John',
      'Doe',
      AppleId.create('apple-123'),
    );

    vi.mocked(mockUserRepository.findById).mockResolvedValue(user);
    vi.mocked(mockUserRepository.delete).mockResolvedValue(undefined);

    const result = await useCase.execute({ userId: user.id.value });

    expect(result.success).toBe(true);
    expect(mockUserRepository.findById).toHaveBeenCalledWith(expect.any(UserId));
    expect(mockUserRepository.delete).toHaveBeenCalledWith(expect.any(UserId));
  });

  it('should return UserNotFoundError when user does not exist', async () => {
    vi.mocked(mockUserRepository.findById).mockResolvedValue(null);

    const result = await useCase.execute({ userId: 'non-existent-id' });

    expect(result.success).toBe(false);
    expect(result.error).toBeInstanceOf(UserNotFoundError);
    expect(mockUserRepository.delete).not.toHaveBeenCalled();
  });

  it('should return UseCaseError when repository throws unexpected error', async () => {
    vi.mocked(mockUserRepository.findById).mockRejectedValue(new Error('DB connection lost'));

    const result = await useCase.execute({ userId: 'user-123' });

    expect(result.success).toBe(false);
    expect(result.error).toBeInstanceOf(UseCaseError);
    expect(result.error?.message).toBe('Failed to delete account');
  });

  it('should pass through AppError from repository', async () => {
    const appError = new UserNotFoundError('Custom not found');
    vi.mocked(mockUserRepository.findById).mockRejectedValue(appError);

    const result = await useCase.execute({ userId: 'user-123' });

    expect(result.success).toBe(false);
    expect(result.error).toBe(appError);
  });
});

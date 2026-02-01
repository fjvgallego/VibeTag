import { describe, it, expect, vi, beforeEach } from 'vitest';
import { LoginWithAppleUseCase } from '../../../../application/use-cases/auth/login-with-apple.use-case';
import { UserRepository } from '../../../../application/ports/user.repository';
import { IAuthProvider } from '../../../../application/ports/auth-provider';
import { ITokenService } from '../../../../application/ports/token-service';
import { LoginWithAppleRequestDTO } from '../../../../application/dtos/login-with-apple.dto';
import { User } from '../../../../domain/entities/user';
import { AppleId } from '../../../../domain/value-objects/ids/apple-id.vo';
import { Email } from '../../../../domain/value-objects/email.vo';

describe('LoginWithAppleUseCase', () => {
  let loginWithAppleUseCase: LoginWithAppleUseCase;
  let mockUserRepository: UserRepository;
  let mockAuthProvider: IAuthProvider;
  let mockTokenService: ITokenService;

  beforeEach(() => {
    mockUserRepository = {
      findByAppleId: vi.fn(),
      save: vi.fn(),
      findById: vi.fn(),
    };

    mockAuthProvider = {
      verifyAppleToken: vi.fn(),
    };

    mockTokenService = {
      generate: vi.fn(),
      verify: vi.fn(),
    };

    loginWithAppleUseCase = new LoginWithAppleUseCase(
      mockUserRepository,
      mockAuthProvider,
      mockTokenService,
    );
  });

  it('should verify token, find user, and return user + token', async () => {
    const request: LoginWithAppleRequestDTO = {
      identityToken: 'valid-token',
      firstName: 'John',
      lastName: 'Doe',
    };

    const appleUserData = {
      appleId: 'apple-123',
      email: 'john@example.com',
    };

    const existingUser = User.create(
      Email.create('john@example.com'),
      'John',
      'Doe',
      AppleId.create('apple-123'),
    );

    vi.mocked(mockAuthProvider.verifyAppleToken).mockResolvedValue(appleUserData);
    vi.mocked(mockUserRepository.findByAppleId).mockResolvedValue(existingUser);
    vi.mocked(mockTokenService.generate).mockReturnValue('generated-jwt-token');

    const result = await loginWithAppleUseCase.execute(request);

    expect(result.success).toBe(true);
    const value = result.getValue();
    expect(value.user.email).toBe('john@example.com');
    expect(value.token).toBe('generated-jwt-token');

    expect(mockAuthProvider.verifyAppleToken).toHaveBeenCalledWith('valid-token');
    expect(mockTokenService.generate).toHaveBeenCalledWith({
      userId: existingUser.id.value,
      email: 'john@example.com',
    });
  });

  it('should create a new user if not found, then return user + token', async () => {
    const request: LoginWithAppleRequestDTO = {
      identityToken: 'valid-token-new-user',
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane@example.com',
    };

    const appleUserData = {
      appleId: 'apple-456',
      email: 'jane@example.com',
    };

    vi.mocked(mockAuthProvider.verifyAppleToken).mockResolvedValue(appleUserData);
    vi.mocked(mockUserRepository.findByAppleId).mockResolvedValue(null);
    vi.mocked(mockTokenService.generate).mockReturnValue('new-user-token');

    const result = await loginWithAppleUseCase.execute(request);

    expect(result.success).toBe(true);
    const value = result.getValue();
    expect(value.user.email).toBe('jane@example.com');
    expect(value.token).toBe('new-user-token');

    expect(mockUserRepository.save).toHaveBeenCalled();
    const savedUserArg = vi.mocked(mockUserRepository.save).mock.calls[0][0];
    expect(savedUserArg.email?.value).toBe('jane@example.com');
    expect(savedUserArg.appleId?.value).toBe('apple-456');
  });
});

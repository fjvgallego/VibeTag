import { ISongRepository } from '../ports/song.repository';
import { UserSongLibraryDTO } from '../dtos/song.dto';
import { Result } from '../../shared/result';
import { AppError, UseCaseError, ValidationError } from '../../domain/errors/app-error';

export class GetUserLibraryUseCase {
  constructor(private readonly songRepository: ISongRepository) {}

  public async execute(
    userId: string,
    page: number,
    limit: number,
  ): Promise<Result<UserSongLibraryDTO[], AppError>> {
    if (page < 1) {
      return Result.fail(new ValidationError('Page must be at least 1'));
    }
    if (limit < 1) {
      return Result.fail(new ValidationError('Limit must be at least 1'));
    }

    try {
      const library = await this.songRepository.findUserLibrary(userId, { page, limit });
      return Result.ok(library);
    } catch (error) {
      console.error('Error fetching user library:', error);
      return Result.fail(
        new UseCaseError('Failed to fetch user library', { cause: error as Error }),
      );
    }
  }
}

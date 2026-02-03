import { ISongRepository } from '../ports/song.repository';
import { UserSongLibraryDTO } from '../dtos/song.dto';
import { Result } from '../../shared/result';
import { AppError, UseCaseError } from '../../domain/errors/app-error';

export class GetUserLibraryUseCase {
  constructor(private readonly songRepository: ISongRepository) {}

  public async execute(
    userId: string,
    page: number,
    limit: number,
  ): Promise<Result<UserSongLibraryDTO[], AppError>> {
    try {
      const library = await this.songRepository.findUserLibrary(userId, { page, limit });
      return Result.ok(library);
    } catch (error) {
      console.error('Error fetching user library:', error);
      return Result.fail(new UseCaseError('Failed to fetch user library'));
    }
  }
}

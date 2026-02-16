import { ISongRepository } from '../ports/song.repository';
import { GetUserLibraryRequestDTO, UserSongLibraryDTO } from '../dtos/song.dto';
import { Result } from '../../shared/result';
import { AppError, UseCaseError, ValidationError } from '../../domain/errors/app-error';
import { UseCase } from './use-case.interface';

export class GetUserLibraryUseCase implements UseCase<
  GetUserLibraryRequestDTO,
  UserSongLibraryDTO[],
  AppError
> {
  constructor(private readonly songRepository: ISongRepository) {}

  public async execute(
    request: GetUserLibraryRequestDTO,
  ): Promise<Result<UserSongLibraryDTO[], AppError>> {
    if (request.page < 1) {
      return Result.fail(new ValidationError('Page must be at least 1'));
    }
    if (request.limit < 1) {
      return Result.fail(new ValidationError('Limit must be at least 1'));
    }

    try {
      const library = await this.songRepository.findUserLibrary(request.userId, {
        page: request.page,
        limit: request.limit,
      });
      return Result.ok(library);
    } catch (error) {
      console.error('Error fetching user library:', error);
      return Result.fail(
        new UseCaseError('Failed to fetch user library', { cause: error as Error }),
      );
    }
  }
}

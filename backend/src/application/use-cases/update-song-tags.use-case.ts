import { UseCase } from './use-case.interface';
import { Result } from '../../shared/result';
import { UpdateSongTagsDTO } from '../dtos/song.dto';
import { IAnalysisRepository } from '../ports/analysis.repository';
import { AppError, UseCaseError } from '../../domain/errors/app-error';
import { UserId } from '../../domain/value-objects/ids/user-id.vo';

export interface UpdateSongTagsInput extends UpdateSongTagsDTO {
  userId: string;
  songId: string;
}

export class UpdateSongTagsUseCase implements UseCase<UpdateSongTagsInput, void, AppError> {
  constructor(private readonly analysisRepository: IAnalysisRepository) {}

  public async execute(request: UpdateSongTagsInput): Promise<Result<void, AppError>> {
    try {
      const userId = UserId.create(request.userId);

      await this.analysisRepository.updateSongTags(userId, request.songId, request.tags, {
        title: request.title,
        artist: request.artist,
      });

      return Result.ok<void, AppError>(undefined);
    } catch (error) {
      console.error(error);
      if (error instanceof AppError) {
        return Result.fail<void, AppError>(error);
      }
      return Result.fail<void, AppError>(new UseCaseError('Failed to update song tags'));
    }
  }
}

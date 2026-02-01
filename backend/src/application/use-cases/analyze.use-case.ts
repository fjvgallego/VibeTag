import { UseCase } from './use-case.interface';
import { Result } from '../../shared/result';
import { AnalyzeRequestDTO, AnalyzeResponseDTO } from '../dtos/analyze.dto';
import { IAnalysisRepository } from '../ports/analysis.repository';
import { IAIService } from '../../domain/services/ai-service.interface';
import { Analysis } from '../../domain/entities/analysis';
import { SongMetadata } from '../../domain/value-objects/song-metadata.vo';
import { VibeTag } from '../../domain/entities/vibe-tag';
import { AppError, UseCaseError } from '../../domain/errors/app-error';
import { VTDate } from '../../domain/value-objects/vt-date.vo';

export class AnalyzeUseCase implements UseCase<AnalyzeRequestDTO, AnalyzeResponseDTO, AppError> {
  constructor(
    private readonly analysisRepository: IAnalysisRepository,
    private readonly aiService: IAIService,
  ) {}

  public async execute(request: AnalyzeRequestDTO): Promise<Result<AnalyzeResponseDTO, AppError>> {
    try {
      const normalizedTitle = request.title?.trim();
      const normalizedArtist = request.artist?.trim();

      const existingAnalysis = await this.analysisRepository.findBySong(
        normalizedTitle,
        normalizedArtist,
      );

      if (existingAnalysis) {
        return Result.ok<AnalyzeResponseDTO, AppError>({
          vibes: existingAnalysis.tags.map((tag) => tag.name),
        });
      }

      const songMetadata = SongMetadata.create(
        normalizedTitle,
        normalizedArtist,
        request.album,
        request.genre,
      );

      // Call external AI service
      const aiVibes = await this.aiService.getVibesForSong(songMetadata);

      // Map strings to VibeTag entities
      const newTags = aiVibes.map((vibe) => VibeTag.create(vibe, 'ai'));

      const newAnalysis = Analysis.create(songMetadata, newTags, VTDate.now());

      await this.analysisRepository.save(newAnalysis);

      return Result.ok<AnalyzeResponseDTO, AppError>({
        vibes: newAnalysis.tags.map((tag) => tag.name),
      });
    } catch (error) {
      console.error(error);
      if (error instanceof AppError) {
        return Result.fail<AnalyzeResponseDTO, AppError>(error);
      }
      return Result.fail<AnalyzeResponseDTO, AppError>(new UseCaseError('Failed to analyze song'));
    }
  }
}

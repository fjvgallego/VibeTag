import { UseCase } from './use-case.interface';
import { Result } from '../../shared/result';
import {
  AnalyzeRequestDTO,
  AnalyzeResponseDTO,
  BatchAnalyzeRequestDTO,
  BatchAnalyzeResponseDTO,
} from '../dtos/analyze.dto';
import { IAnalysisRepository } from '../ports/analysis.repository';
import { IAIService } from '../../domain/services/ai-service.interface';
import { Analysis } from '../../domain/entities/analysis';
import { SongMetadata } from '../../domain/value-objects/song-metadata.vo';
import { VibeTag } from '../../domain/entities/vibe-tag';
import { AppError, UseCaseError } from '../../domain/errors/app-error';
import { VTDate } from '../../domain/value-objects/vt-date.vo';
import { randomUUID } from 'crypto';

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
        request.userId,
        request.songId,
      );

      if (existingAnalysis) {
        return Result.ok<AnalyzeResponseDTO, AppError>({
          tags: existingAnalysis.tags.map((tag) => tag.name),
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

      const songId = request.songId || randomUUID();
      const newAnalysis = Analysis.create(songMetadata, newTags, VTDate.now(), songId);

      await this.analysisRepository.save(newAnalysis);

      return Result.ok<AnalyzeResponseDTO, AppError>({
        tags: newAnalysis.tags.map((tag) => tag.name),
      });
    } catch (error) {
      console.error(error);
      if (error instanceof AppError) {
        return Result.fail<AnalyzeResponseDTO, AppError>(error);
      }
      return Result.fail<AnalyzeResponseDTO, AppError>(new UseCaseError('Failed to analyze song'));
    }
  }

  public async executeBatch(
    request: BatchAnalyzeRequestDTO,
  ): Promise<Result<BatchAnalyzeResponseDTO, AppError>> {
    try {
      const results: { songId?: string; title: string; tags: string[] }[] = [];

      for (const song of request.songs) {
        const normalizedTitle = song.title?.trim();
        const normalizedArtist = song.artist?.trim();

        // Step A: Cache Check
        const existingAnalysis = await this.analysisRepository.findBySong(
          normalizedTitle,
          normalizedArtist,
          request.userId,
          song.songId,
        );

        if (existingAnalysis) {
          results.push({
            songId: song.songId,
            title: song.title,
            tags: existingAnalysis.tags.map((t) => t.name),
          });
          continue; // No delay needed if found in cache
        }

        // Step B: AI Analysis
        const songMetadata = SongMetadata.create(
          normalizedTitle,
          normalizedArtist,
          song.album,
          song.genre,
        );

        const aiVibes = await this.aiService.getVibesForSong(songMetadata);
        const newTags = aiVibes.map((vibe) => VibeTag.create(vibe, 'ai'));

        const songId = song.songId || randomUUID();
        const newAnalysis = Analysis.create(songMetadata, newTags, VTDate.now(), songId);

        await this.analysisRepository.save(newAnalysis);

        results.push({
          songId: song.songId,
          title: song.title,
          tags: newAnalysis.tags.map((t) => t.name),
        });

        // Step C: Delay to respect rate limits (4 seconds)
        // Only delay if it's NOT the last song being analyzed via AI in this batch
        const isLastSong = request.songs.indexOf(song) === request.songs.length - 1;
        if (!isLastSong) {
          await new Promise((resolve) => setTimeout(resolve, 4000));
        }
      }

      return Result.ok<BatchAnalyzeResponseDTO, AppError>({ results });
    } catch (error) {
      console.error(error);
      if (error instanceof AppError) {
        return Result.fail<BatchAnalyzeResponseDTO, AppError>(error);
      }
      return Result.fail<BatchAnalyzeResponseDTO, AppError>(
        new UseCaseError('Failed to process batch analysis'),
      );
    }
  }
}

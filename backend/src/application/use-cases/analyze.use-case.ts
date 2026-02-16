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
      const normalizedTitle = request.title?.trim() ?? '';
      const normalizedArtist = request.artist?.trim() ?? '';

      const existingAnalysis = await this.analysisRepository.findBySong(
        normalizedTitle,
        normalizedArtist,
        request.userId,
        request.songId,
      );

      const hasAITags = existingAnalysis?.tags.some((tag) => tag.source === 'ai');

      if (existingAnalysis && hasAITags) {
        if (request.userId) {
          // Ensure song is linked to user's library even on cache hit
          const aiOnlyTags = existingAnalysis.tags.filter((tag) => tag.source === 'ai');
          const aiOnlyAnalysis = Analysis.create(
            existingAnalysis.songMetadata,
            aiOnlyTags,
            existingAnalysis.createdAt,
            existingAnalysis.songId.value,
            existingAnalysis.id.value,
          );
          await this.analysisRepository.save(aiOnlyAnalysis, request.userId);
        }

        return Result.ok<AnalyzeResponseDTO, AppError>({
          songId: existingAnalysis.songId.value,
          tags: existingAnalysis.tags
            .filter((tag) => tag.source === 'ai')
            .map((tag) => ({
              name: tag.name,
              description: tag.description || undefined,
            })),
        });
      }

      const songMetadata = SongMetadata.create({
        title: normalizedTitle,
        artist: normalizedArtist,
        appleMusicId: request.appleMusicId,
        album: request.album,
        genre: request.genre,
        artworkUrl: request.artworkUrl,
      });

      // Call external AI service
      const aiVibes = await this.aiService.getVibesForSong(songMetadata);

      // Map to VibeTag entities
      const newTags = aiVibes.map((vibe) =>
        VibeTag.create(vibe.name, 'ai', undefined, vibe.description),
      );

      const songId = request.songId || existingAnalysis?.songId.value || randomUUID();
      const newAnalysis = Analysis.create(songMetadata, newTags, VTDate.now(), songId);

      await this.analysisRepository.save(newAnalysis, request.userId);

      return Result.ok<AnalyzeResponseDTO, AppError>({
        songId: newAnalysis.songId.value,
        tags: newAnalysis.tags.map((tag) => ({
          name: tag.name,
          description: tag.description || undefined,
        })),
      });
    } catch (error) {
      console.error(error);
      if (error instanceof AppError) {
        return Result.fail<AnalyzeResponseDTO, AppError>(error);
      }
      return Result.fail<AnalyzeResponseDTO, AppError>(
        new UseCaseError('Failed to analyze song', { cause: error as Error }),
      );
    }
  }

  public async executeBatch(
    request: BatchAnalyzeRequestDTO,
  ): Promise<Result<BatchAnalyzeResponseDTO, AppError>> {
    try {
      const results: {
        songId?: string;
        title: string;
        tags: { name: string; description?: string }[];
      }[] = [];

      for (let i = 0; i < request.songs.length; i++) {
        const song = request.songs[i];
        const normalizedTitle = song.title?.trim() ?? '';
        const normalizedArtist = song.artist?.trim() ?? '';

        // Step A: Cache Check
        const existingAnalysis = await this.analysisRepository.findBySong(
          normalizedTitle,
          normalizedArtist,
          request.userId,
          song.songId,
        );

        const hasAITags = existingAnalysis?.tags.some((tag) => tag.source === 'ai');

        if (existingAnalysis && hasAITags) {
          if (request.userId) {
            // Ensure song is linked to user's library even on cache hit
            const aiOnlyTags = existingAnalysis.tags.filter((tag) => tag.source === 'ai');
            const aiOnlyAnalysis = Analysis.create(
              existingAnalysis.songMetadata,
              aiOnlyTags,
              existingAnalysis.createdAt,
              existingAnalysis.songId.value,
              existingAnalysis.id.value,
            );
            await this.analysisRepository.save(aiOnlyAnalysis, request.userId);
          }

          results.push({
            songId: existingAnalysis.songId.value,
            title: song.title,
            tags: existingAnalysis.tags
              .filter((tag) => tag.source === 'ai')
              .map((t) => ({
                name: t.name,
                description: t.description || undefined,
              })),
          });
          continue; // No delay needed if found in cache
        }

        // Step B: AI Analysis
        const songMetadata = SongMetadata.create({
          title: normalizedTitle,
          artist: normalizedArtist,
          appleMusicId: song.appleMusicId,
          album: song.album,
          genre: song.genre,
          artworkUrl: song.artworkUrl,
        });

        const aiVibes = await this.aiService.getVibesForSong(songMetadata);
        const newTags = aiVibes.map((vibe) =>
          VibeTag.create(vibe.name, 'ai', undefined, vibe.description),
        );

        const songId = song.songId || existingAnalysis?.songId.value || randomUUID();
        const newAnalysis = Analysis.create(songMetadata, newTags, VTDate.now(), songId);

        await this.analysisRepository.save(newAnalysis, request.userId);

        results.push({
          songId: newAnalysis.songId.value,
          title: song.title,
          tags: newAnalysis.tags.map((t) => ({
            name: t.name,
            description: t.description || undefined,
          })),
        });

        // Step C: Delay to respect rate limits (1 second)
        // Only delay if it's NOT the last song being analyzed via AI in this batch
        const isLastSong = i === request.songs.length - 1;
        if (!isLastSong) {
          await new Promise((resolve) => setTimeout(resolve, 1000));
        }
      }

      return Result.ok<BatchAnalyzeResponseDTO, AppError>({ results });
    } catch (error) {
      console.error(error);
      if (error instanceof AppError) {
        return Result.fail<BatchAnalyzeResponseDTO, AppError>(error);
      }
      return Result.fail<BatchAnalyzeResponseDTO, AppError>(
        new UseCaseError('Failed to process batch analysis', { cause: error as Error }),
      );
    }
  }
}

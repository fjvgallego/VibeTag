import { IAIService } from '../../domain/services/ai-service.interface';
import { ISongRepository } from '../ports/song.repository';
import { GeneratePlaylistRequestDTO, GeneratePlaylistResponseDTO } from '../dtos/playlist.dto';
import { Result } from '../../shared/result';
import { AppError, UseCaseError } from '../../domain/errors/app-error';
import { UseCase } from './use-case.interface';

export class GeneratePlaylistUseCase implements UseCase<
  GeneratePlaylistRequestDTO,
  GeneratePlaylistResponseDTO,
  AppError
> {
  constructor(
    private readonly aiService: IAIService,
    private readonly songRepository: ISongRepository,
  ) {}

  public async execute(
    request: GeneratePlaylistRequestDTO,
  ): Promise<Result<GeneratePlaylistResponseDTO, AppError>> {
    try {
      // 1. Analyze user prompt to get target keywords
      const searchTags = await this.aiService.analyzeUserSentiment(request.userPrompt);

      // 2. Search songs in user library that match these tags (any match)
      const matchingSongs = await this.songRepository.findSongsByTags(searchTags, request.userId);

      // 3. Smart Ranking
      // Score each song based on how many keywords it matches
      const rankedSongs = matchingSongs
        .map((song) => {
          let score = 0;
          for (const keyword of searchTags) {
            const normalizedKeyword = keyword.toLowerCase();
            const matches = song.tags.some(
              (t) =>
                t.name.toLowerCase().includes(normalizedKeyword) ||
                t.description?.toLowerCase().includes(normalizedKeyword),
            );
            if (matches) {
              score += 1;
            }
          }
          return { song, score };
        })
        .sort((a, b) => {
          // Sort by score descending
          if (b.score !== a.score) {
            return b.score - a.score;
          }
          // Tie-breaker: date added (createdAt) descending
          return b.song.createdAt.getTime() - a.song.createdAt.getTime();
        })
        .slice(0, 50);

      // 4. Map to DTO
      const response: GeneratePlaylistResponseDTO = {
        playlistTitle: `Mix: ${request.userPrompt}`,
        description: `Your personalized vibe based on "${request.userPrompt}". Keywords: ${searchTags.join(', ')}`,
        usedTags: searchTags,
        songs: rankedSongs.map(({ song }) => ({
          id: song.id.value,
          title: song.metadata.title,
          artist: song.metadata.artist,
          appleMusicId: song.metadata.appleMusicId,
          artworkUrl: song.metadata.artworkUrl,
          tags: song.tags.map((t) => ({
            name: t.name,
            type: t.source === 'ai' ? 'SYSTEM' : 'USER',
          })),
        })),
      };

      console.log('GENERATE PLAYLIST USE CASE RESPONSE');
      console.log('===================================');
      console.log(response);
      console.log();

      return Result.ok(response);
    } catch (error) {
      console.error('Playlist generation failed:', error);
      if (error instanceof AppError) {
        return Result.fail(error);
      }
      return Result.fail(
        new UseCaseError('Failed to generate playlist', { cause: error as Error }),
      );
    }
  }
}

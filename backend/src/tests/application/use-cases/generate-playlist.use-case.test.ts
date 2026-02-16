import { describe, it, expect, vi, beforeEach } from 'vitest';
import { GeneratePlaylistUseCase } from '../../../application/use-cases/generate-playlist.use-case';
import { IAIService } from '../../../domain/services/ai-service.interface';
import { ISongRepository } from '../../../application/ports/song.repository';
import { Song } from '../../../domain/entities/song';
import { VibeTag } from '../../../domain/entities/vibe-tag';
import { GeneratePlaylistRequestDTO } from '../../../application/dtos/playlist.dto';

describe('GeneratePlaylistUseCase', () => {
  let useCase: GeneratePlaylistUseCase;
  let mockAiService: IAIService;
  let mockSongRepository: ISongRepository;

  beforeEach(() => {
    mockAiService = {
      getVibesForSong: vi.fn(),
      analyzeUserSentiment: vi.fn(),
    };
    mockSongRepository = {
      findUserLibrary: vi.fn(),
      findSongsByTags: vi.fn(),
    };
    useCase = new GeneratePlaylistUseCase(mockAiService, mockSongRepository);
  });

  const request: GeneratePlaylistRequestDTO = {
    userId: 'user-123',
    userPrompt: 'Música para programar',
  };

  it('Scenario 1: should translate prompt and find songs by standard tags', async () => {
    // Arrange
    const aiKeywords = ['Coding', 'Focus'];
    vi.mocked(mockAiService.analyzeUserSentiment).mockResolvedValue(aiKeywords);

    const mockSongs = [
      Song.create('s1', 'Song 1', 'Artist 1', [VibeTag.create('Coding', 'ai')]),
      Song.create('s2', 'Song 2', 'Artist 2', [VibeTag.create('Focus', 'ai')]),
    ];
    vi.mocked(mockSongRepository.findSongsByTags).mockResolvedValue(mockSongs);

    // Act
    const result = await useCase.execute(request);

    // Assert
    expect(result.success).toBe(true);
    const data = result.getValue();
    expect(data.usedTags).toEqual(['Coding', 'Focus']);
    expect(data.songs).toHaveLength(2);
    expect(mockAiService.analyzeUserSentiment).toHaveBeenCalledWith('Música para programar');
    expect(mockSongRepository.findSongsByTags).toHaveBeenCalledWith(
      ['Coding', 'Focus'],
      'user-123',
    );
  });

  it('Scenario 2: should find songs by tags extracted from complex prompt (Description Match)', async () => {
    // Arrange
    const complexRequest: GeneratePlaylistRequestDTO = {
      userId: 'user-123',
      userPrompt: 'Feeling nostalgic about old love',
    };
    const aiKeywords = ['Nostalgia', 'Relationships'];
    vi.mocked(mockAiService.analyzeUserSentiment).mockResolvedValue(aiKeywords);

    const mockSongs = [
      Song.create('s3', 'Nostalgic Song', 'Artist 3', [
        VibeTag.create('Flashbacks', 'ai', undefined, 'Relationships and past memories'),
      ]),
    ];
    vi.mocked(mockSongRepository.findSongsByTags).mockResolvedValue(mockSongs);

    // Act
    const result = await useCase.execute(complexRequest);

    // Assert
    expect(result.success).toBe(true);
    expect(result.getValue().usedTags).toEqual(['Nostalgia', 'Relationships']);
    expect(mockSongRepository.findSongsByTags).toHaveBeenCalledWith(
      ['Nostalgia', 'Relationships'],
      'user-123',
    );
  });

  it('Scenario 3: should return empty song list if no songs match', async () => {
    // Arrange
    vi.mocked(mockAiService.analyzeUserSentiment).mockResolvedValue(['Rare Vibe']);
    vi.mocked(mockSongRepository.findSongsByTags).mockResolvedValue([]);

    // Act
    const result = await useCase.execute(request);

    // Assert
    expect(result.success).toBe(true);
    expect(result.getValue().songs).toHaveLength(0);
    expect(result.getValue().usedTags).toEqual(['Rare Vibe']);
  });
});

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { AnalyzeUseCase } from '../../../application/use-cases/analyze.use-case';
import { IAnalysisRepository } from '../../../application/ports/analysis.repository';
import { IAIService } from '../../../domain/services/ai-service.interface';
import { Analysis } from '../../../domain/entities/analysis';
import { SongMetadata } from '../../../domain/value-objects/song-metadata.vo';
import { VibeTag } from '../../../domain/entities/vibe-tag';
import { AnalyzeRequestDTO, BatchAnalyzeRequestDTO } from '../../../application/dtos/analyze.dto';
import { AIServiceError, ValidationError } from '../../../domain/errors/app-error';
import { VTDate } from '../../../domain/value-objects/vt-date.vo';

describe('AnalyzeUseCase', () => {
  let analyzeUseCase: AnalyzeUseCase;
  let mockAnalysisRepository: IAnalysisRepository;
  let mockAiService: IAIService;

  beforeEach(() => {
    vi.useFakeTimers();
    mockAnalysisRepository = {
      findBySong: vi.fn(),
      save: vi.fn(),
      updateSongTags: vi.fn(),
    };
    mockAiService = {
      getVibesForSong: vi.fn(),
      analyzeUserSentiment: vi.fn(),
    };
    analyzeUseCase = new AnalyzeUseCase(mockAnalysisRepository, mockAiService);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const request: AnalyzeRequestDTO = {
    title: 'Test Song',
    artist: 'Test Artist',
    album: 'Test Album',
    genre: 'Pop',
  };

  const songMetadata = SongMetadata.create({
    title: request.title,
    artist: request.artist,
    album: request.album,
    genre: request.genre,
  });

  it('should return cached vibes if analysis exists (Cache Hit)', async () => {
    // Arrange
    const existingTags = [
      VibeTag.create('Chill', 'ai', undefined, 'Relaxed'),
      VibeTag.create('Happy', 'user'),
    ];
    const existingAnalysis = Analysis.create(songMetadata, existingTags, VTDate.now(), 'song-123');

    vi.mocked(mockAnalysisRepository.findBySong).mockResolvedValue(existingAnalysis);

    // Act
    const result = await analyzeUseCase.execute(request);

    // Assert
    expect(result.success).toBe(true);
    expect(result.getValue().songId).toBe('song-123');
    expect(result.getValue().tags).toEqual([{ name: 'chill', description: 'Relaxed' }]);
    expect(mockAnalysisRepository.findBySong).toHaveBeenCalledWith(
      request.title,
      request.artist,
      undefined,
      undefined,
    );
    expect(mockAiService.getVibesForSong).not.toHaveBeenCalled();
    expect(mockAnalysisRepository.save).not.toHaveBeenCalled();
  });

  it('should call AI service and save result if analysis does not exist (Cache Miss)', async () => {
    // Arrange
    vi.mocked(mockAnalysisRepository.findBySong).mockResolvedValue(null);
    const aiVibes = [
      { name: 'Melancholic', description: 'Sad vibe' },
      { name: 'Dreamy', description: 'Floating vibe' },
    ];
    vi.mocked(mockAiService.getVibesForSong).mockResolvedValue(aiVibes);

    // Act
    const result = await analyzeUseCase.execute(request);

    // Assert
    expect(result.success).toBe(true);
    expect(result.getValue().songId).toBeDefined();
    expect(result.getValue().songId).toHaveLength(36); // UUID length
    expect(result.getValue().tags).toEqual([
      { name: 'melancholic', description: 'Sad vibe' },
      { name: 'dreamy', description: 'Floating vibe' },
    ]);
    expect(mockAnalysisRepository.findBySong).toHaveBeenCalledWith(
      request.title,
      request.artist,
      undefined,
      undefined,
    );
    expect(mockAiService.getVibesForSong).toHaveBeenCalledWith(
      expect.objectContaining({
        title: request.title,
        artist: request.artist,
      }),
    );
    expect(mockAnalysisRepository.save).toHaveBeenCalled();
  });

  it('should return failure if AI service throws an error and NOT save to repository', async () => {
    // Arrange
    vi.mocked(mockAnalysisRepository.findBySong).mockResolvedValue(null);
    vi.mocked(mockAiService.getVibesForSong).mockRejectedValue(
      new AIServiceError('Gemini API call failed'),
    );

    // Act
    const result = await analyzeUseCase.execute(request);

    // Assert
    expect(result.isFailure).toBe(true);
    expect(result.error).toBeInstanceOf(AIServiceError);
    expect(mockAnalysisRepository.save).not.toHaveBeenCalled();
  });

  it('should pass through AppError instances (e.g., ValidationError)', async () => {
    // Arrange
    const validationError = new ValidationError('Invalid song metadata');
    vi.mocked(mockAnalysisRepository.findBySong).mockRejectedValue(validationError);

    // Act
    const result = await analyzeUseCase.execute(request);

    // Assert
    expect(result.isFailure).toBe(true);
    expect(result.error).toBe(validationError);
  });

  describe('executeBatch', () => {
    it('should process a batch of songs, using cache when available and AI when not', async () => {
      // Arrange
      const batchRequest: BatchAnalyzeRequestDTO = {
        songs: [
          { title: 'Song 1', artist: 'Artist 1' },
          { title: 'Song 2', artist: 'Artist 2' },
        ],
      };

      // Mock Cache Hit for Song 1
      const song1Metadata = SongMetadata.create({ title: 'Song 1', artist: 'Artist 1' });
      const existingTags = [VibeTag.create('Chill', 'ai', undefined, 'Cool')];
      const existingAnalysis = Analysis.create(song1Metadata, existingTags, VTDate.now(), 's1');
      vi.mocked(mockAnalysisRepository.findBySong).mockResolvedValueOnce(existingAnalysis);

      // Mock Cache Miss for Song 2
      vi.mocked(mockAnalysisRepository.findBySong).mockResolvedValueOnce(null);
      vi.mocked(mockAiService.getVibesForSong).mockResolvedValue([
        { name: 'Energetic', description: 'Fast' },
      ]);

      // Act
      const promise = analyzeUseCase.executeBatch(batchRequest);

      // Advance timers to handle the 1s delay after AI analysis
      // Song 1 is cache hit, so no delay before Song 2.
      // Song 2 is AI analysis, so there's a 1s delay after it.
      await vi.runAllTimersAsync();

      const result = await promise;

      // Assert
      expect(result.success).toBe(true);
      const data = result.getValue();
      expect(data.results).toHaveLength(2);
      expect(data.results[0].songId).toBe('s1');
      expect(data.results[0].tags).toEqual([{ name: 'chill', description: 'Cool' }]);
      expect(data.results[1].songId).toBeDefined();
      expect(data.results[1].songId).toHaveLength(36);
      expect(data.results[1].tags).toEqual([{ name: 'energetic', description: 'Fast' }]);

      expect(mockAnalysisRepository.findBySong).toHaveBeenCalledTimes(2);
      expect(mockAiService.getVibesForSong).toHaveBeenCalledTimes(1);
      expect(mockAnalysisRepository.save).toHaveBeenCalledTimes(1);
    });

    it('should continue processing remaining songs when AI fails for one song', async () => {
      // Arrange
      const batchRequest: BatchAnalyzeRequestDTO = {
        songs: [
          { title: 'Song 1', artist: 'Artist 1' },
          { title: 'Song 2', artist: 'Artist 2' },
          { title: 'Song 3', artist: 'Artist 3' },
        ],
      };

      // All cache misses
      vi.mocked(mockAnalysisRepository.findBySong).mockResolvedValue(null);

      // Song 1: success, Song 2: AI fails, Song 3: success
      vi.mocked(mockAiService.getVibesForSong)
        .mockResolvedValueOnce([{ name: 'Chill', description: 'Relaxed' }])
        .mockRejectedValueOnce(new AIServiceError('Gemini API call failed'))
        .mockResolvedValueOnce([{ name: 'Energetic', description: 'Fast' }]);

      // Act
      const promise = analyzeUseCase.executeBatch(batchRequest);
      await vi.runAllTimersAsync();
      const result = await promise;

      // Assert
      expect(result.success).toBe(true);
      const data = result.getValue();
      expect(data.results).toHaveLength(3);

      // Song 1: success
      expect(data.results[0].tags).toEqual([{ name: 'chill', description: 'Relaxed' }]);
      expect(data.results[0].error).toBeUndefined();

      // Song 2: failed with error
      expect(data.results[1].tags).toEqual([]);
      expect(data.results[1].error).toBe('Gemini API call failed');

      // Song 3: success (batch continued)
      expect(data.results[2].tags).toEqual([{ name: 'energetic', description: 'Fast' }]);
      expect(data.results[2].error).toBeUndefined();

      // Save called only for successful songs
      expect(mockAnalysisRepository.save).toHaveBeenCalledTimes(2);
    });
  });
});

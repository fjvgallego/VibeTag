import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AnalyzeUseCase } from '../../../application/use-cases/analyze.use-case';
import { IAnalysisRepository } from '../../../application/ports/analysis.repository';
import { IAIService } from '../../../domain/services/ai-service.interface';
import { Analysis } from '../../../domain/entities/analysis';
import { SongMetadata } from '../../../domain/value-objects/song-metadata';
import { VibeTag } from '../../../domain/entities/vibe-tag';
import { AnalyzeRequestDTO } from '../../../application/dtos/analyze.dto';
import { ValidationError } from '../../../domain/errors/app-error';

describe('AnalyzeUseCase', () => {
  let analyzeUseCase: AnalyzeUseCase;
  let mockAnalysisRepository: IAnalysisRepository;
  let mockAiService: IAIService;

  beforeEach(() => {
    mockAnalysisRepository = {
      findBySong: vi.fn(),
      save: vi.fn(),
    };
    mockAiService = {
      getVibesForSong: vi.fn(),
    };
    analyzeUseCase = new AnalyzeUseCase(mockAnalysisRepository, mockAiService);
  });

  const request: AnalyzeRequestDTO = {
    title: 'Test Song',
    artist: 'Test Artist',
    album: 'Test Album',
    genre: 'Pop',
  };

  const songMetadata = SongMetadata.create(
    request.title,
    request.artist,
    request.album,
    request.genre,
  );

  it('should return cached vibes if analysis exists (Cache Hit)', async () => {
    // Arrange
    const existingTags = [VibeTag.create('Chill', 'ai'), VibeTag.create('Happy', 'user')];
    const existingAnalysis = Analysis.create(songMetadata, existingTags, new Date());

    vi.mocked(mockAnalysisRepository.findBySong).mockResolvedValue(existingAnalysis);

    // Act
    const result = await analyzeUseCase.execute(request);

    // Assert
    expect(result.success).toBe(true);
    expect(result.getValue().vibes).toEqual(['chill', 'happy']);
    expect(mockAnalysisRepository.findBySong).toHaveBeenCalledWith(request.title, request.artist);
    expect(mockAiService.getVibesForSong).not.toHaveBeenCalled();
    expect(mockAnalysisRepository.save).not.toHaveBeenCalled();
  });

  it('should call AI service and save result if analysis does not exist (Cache Miss)', async () => {
    // Arrange
    vi.mocked(mockAnalysisRepository.findBySong).mockResolvedValue(null);
    const aiVibes = ['Melancholic', 'Dreamy'];
    vi.mocked(mockAiService.getVibesForSong).mockResolvedValue(aiVibes);

    // Act
    const result = await analyzeUseCase.execute(request);

    // Assert
    expect(result.success).toBe(true);
    expect(result.getValue().vibes).toEqual(['melancholic', 'dreamy']);
    expect(mockAnalysisRepository.findBySong).toHaveBeenCalledWith(request.title, request.artist);
    expect(mockAiService.getVibesForSong).toHaveBeenCalledWith(
      expect.objectContaining({
        title: request.title,
        artist: request.artist,
      }),
    );
    expect(mockAnalysisRepository.save).toHaveBeenCalled();
  });

  it('should return failure if AI service throws an error', async () => {
    // Arrange
    vi.mocked(mockAnalysisRepository.findBySong).mockResolvedValue(null);
    vi.mocked(mockAiService.getVibesForSong).mockRejectedValue(new Error('AI Service Error'));

    // Act
    const result = await analyzeUseCase.execute(request);

    // Assert
    expect(result.isFailure).toBe(true);
    expect(result.error).toBeDefined();
    // Verify error message if possible, or just that it failed
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
});

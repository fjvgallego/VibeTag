import { describe, it, expect, vi, beforeEach, Mock } from 'vitest';
import { UpdateSongTagsUseCase } from '../../../application/use-cases/update-song-tags.use-case';
import { IAnalysisRepository } from '../../../application/ports/analysis.repository';
import { UserId } from '../../../domain/value-objects/ids/user-id.vo';
import { UseCaseError } from '../../../domain/errors/app-error';

describe('UpdateSongTagsUseCase', () => {
  let useCase: UpdateSongTagsUseCase;
  let mockAnalysisRepository: IAnalysisRepository;

  beforeEach(() => {
    mockAnalysisRepository = {
      findBySong: vi.fn(),
      save: vi.fn(),
      updateSongTags: vi.fn(),
    };
    useCase = new UpdateSongTagsUseCase(mockAnalysisRepository);
  });

  it('should successfully update song tags', async () => {
    const userId = 'user-123';
    const songId = 'song-456';
    const tags = ['vibe1', 'vibe2'];

    (mockAnalysisRepository.updateSongTags as Mock).mockResolvedValue(undefined);

    const result = await useCase.execute({ userId, songId, tags });

    expect(result.success).toBe(true);
    expect(mockAnalysisRepository.updateSongTags).toHaveBeenCalledWith(
      expect.any(UserId),
      songId,
      tags,
    );

    const callUserId = (mockAnalysisRepository.updateSongTags as Mock).mock.calls[0][0];
    expect(callUserId.value).toBe(userId);
  });

  it('should return failure if repository throws an AppError', async () => {
    const error = new UseCaseError('Database error');
    mockAnalysisRepository.updateSongTags = vi.fn().mockRejectedValue(error);

    const result = await useCase.execute({
      userId: 'user-123',
      songId: 'song-456',
      tags: ['tag1'],
    });

    expect(result.success).toBe(false);
    expect(result.error).toBe(error);
  });

  it('should return failure if repository throws an unexpected error', async () => {
    mockAnalysisRepository.updateSongTags = vi.fn().mockRejectedValue(new Error('Unexpected'));

    const result = await useCase.execute({
      userId: 'user-123',
      songId: 'song-456',
      tags: ['tag1'],
    });

    expect(result.success).toBe(false);
    expect(result.error).toBeInstanceOf(UseCaseError);
    expect(result.error?.message).toBe('Failed to update song tags');
  });
});

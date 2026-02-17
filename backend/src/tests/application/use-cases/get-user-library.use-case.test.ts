import { describe, it, expect, vi, beforeEach } from 'vitest';
import { GetUserLibraryUseCase } from '../../../application/use-cases/get-user-library.use-case';
import { ISongRepository } from '../../../application/ports/song.repository';
import { ValidationError, UseCaseError } from '../../../domain/errors/app-error';

describe('GetUserLibraryUseCase', () => {
  let useCase: GetUserLibraryUseCase;
  let mockSongRepository: ISongRepository;

  beforeEach(() => {
    mockSongRepository = {
      findUserLibrary: vi.fn(),
      findSongsByTags: vi.fn(),
    };
    useCase = new GetUserLibraryUseCase(mockSongRepository);
  });

  it('should return failure if page is less than 1', async () => {
    const result = await useCase.execute({ userId: 'user-123', page: 0, limit: 10 });

    expect(result.success).toBe(false);
    expect(result.error).toBeInstanceOf(ValidationError);
    expect(result.error?.message).toBe('Page must be at least 1');
  });

  it('should return failure if limit is less than 1', async () => {
    const result = await useCase.execute({ userId: 'user-123', page: 1, limit: 0 });

    expect(result.success).toBe(false);
    expect(result.error).toBeInstanceOf(ValidationError);
    expect(result.error?.message).toBe('Limit must be at least 1');
  });

  it('should call repository with correct parameters if validation passes', async () => {
    const userId = 'user-123';
    const page = 1;
    const limit = 10;
    const mockLibrary = [{ id: 'song-1', title: 'Title', artist: 'Artist', tags: [] }];

    vi.mocked(mockSongRepository.findUserLibrary).mockResolvedValue(mockLibrary);

    const result = await useCase.execute({ userId, page, limit });

    expect(result.success).toBe(true);
    expect(result.getValue()).toEqual(mockLibrary);
    expect(mockSongRepository.findUserLibrary).toHaveBeenCalledWith(userId, { page, limit });
  });

  it('should return failure if repository throws', async () => {
    vi.mocked(mockSongRepository.findUserLibrary).mockRejectedValue(
      new Error('DB connection error'),
    );

    const result = await useCase.execute({ userId: 'user-123', page: 1, limit: 10 });

    expect(result.success).toBe(false);
    expect(result.error).toBeInstanceOf(UseCaseError);
    expect(result.error?.message).toBe('Failed to fetch user library');
  });

  it('should return empty array when user has no songs', async () => {
    vi.mocked(mockSongRepository.findUserLibrary).mockResolvedValue([]);

    const result = await useCase.execute({ userId: 'user-123', page: 1, limit: 50 });

    expect(result.success).toBe(true);
    expect(result.getValue()).toEqual([]);
  });
});

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { GetUserLibraryUseCase } from '../../../application/use-cases/get-user-library.use-case';
import { ISongRepository } from '../../../application/ports/song.repository';
import { ValidationError } from '../../../domain/errors/app-error';

describe('GetUserLibraryUseCase', () => {
  let useCase: GetUserLibraryUseCase;
  let mockSongRepository: ISongRepository;

  beforeEach(() => {
    mockSongRepository = {
      save: vi.fn(),
      findById: vi.fn(),
      findUserLibrary: vi.fn(),
      findSongsByTags: vi.fn(),
    };
    useCase = new GetUserLibraryUseCase(mockSongRepository);
  });

  it('should return failure if page is less than 1', async () => {
    const result = await useCase.execute('user-123', 0, 10);

    expect(result.success).toBe(false);
    expect(result.error).toBeInstanceOf(ValidationError);
    expect(result.error?.message).toBe('Page must be at least 1');
  });

  it('should return failure if limit is less than 1', async () => {
    const result = await useCase.execute('user-123', 1, 0);

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

    const result = await useCase.execute(userId, page, limit);

    expect(result.success).toBe(true);
    expect(result.getValue()).toEqual(mockLibrary);
    expect(mockSongRepository.findUserLibrary).toHaveBeenCalledWith(userId, { page, limit });
  });
});

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { GeminiAIService } from '../../../infrastructure/services/gemini-ai.service';
import { AIServiceError } from '../../../domain/errors/app-error';
import { SongMetadata } from '../../../domain/value-objects/song-metadata.vo';
import { ITextSanitizer } from '../../../shared/text-sanitizer';

vi.mock('ai', () => ({
  generateText: vi.fn(),
}));

vi.mock('@ai-sdk/google', () => ({
  createGoogleGenerativeAI: vi.fn(() => vi.fn()),
}));

import { generateText } from 'ai';

describe('GeminiAIService', () => {
  let service: GeminiAIService;
  let mockSanitizer: ITextSanitizer;

  const song = SongMetadata.create({
    title: 'Test Song',
    artist: 'Test Artist',
    album: 'Test Album',
    genre: 'Pop',
  });

  beforeEach(() => {
    vi.clearAllMocks();
    mockSanitizer = {
      sanitize: vi.fn((text: string) => text),
    };
    service = new GeminiAIService('fake-api-key', mockSanitizer);
  });

  describe('getVibesForSong', () => {
    it('should return parsed vibes on valid AI response', async () => {
      const validResponse = JSON.stringify([
        { name: 'Chill', description: 'Relaxed vibes' },
        { name: 'Summer', description: 'Warm feeling' },
      ]);
      vi.mocked(generateText).mockResolvedValue({ text: validResponse } as unknown);

      const result = await service.getVibesForSong(song);

      expect(result).toEqual([
        { name: 'chill', description: 'Relaxed vibes' },
        { name: 'summer', description: 'Warm feeling' },
      ]);
    });

    it('should throw AIServiceError when API call fails', async () => {
      vi.mocked(generateText).mockRejectedValue(new Error('Network error'));

      await expect(service.getVibesForSong(song)).rejects.toThrow(AIServiceError);
      await expect(service.getVibesForSong(song)).rejects.toThrow('Gemini API call failed');
    });

    it('should throw AIServiceError when response is unparseable', async () => {
      vi.mocked(generateText).mockResolvedValue({ text: 'not valid json' } as unknown);

      await expect(service.getVibesForSong(song)).rejects.toThrow(AIServiceError);
      await expect(service.getVibesForSong(song)).rejects.toThrow('unparseable or empty');
    });

    it('should throw AIServiceError when response is an empty array', async () => {
      vi.mocked(generateText).mockResolvedValue({ text: '[]' } as unknown);

      await expect(service.getVibesForSong(song)).rejects.toThrow(AIServiceError);
    });

    it('should throw AIServiceError when response is not an array', async () => {
      vi.mocked(generateText).mockResolvedValue({ text: '{"name": "Chill"}' } as unknown);

      await expect(service.getVibesForSong(song)).rejects.toThrow(AIServiceError);
    });
  });

  describe('analyzeUserSentiment', () => {
    it('should return parsed sentiment tags on valid response', async () => {
      const validResponse = JSON.stringify(['Chill', 'Focus', 'Ambient']);
      vi.mocked(generateText).mockResolvedValue({ text: validResponse } as unknown);

      const result = await service.analyzeUserSentiment('relaxing music');

      expect(result).toEqual(['Chill', 'Focus', 'Ambient']);
    });

    it('should fallback to tokenization when API fails', async () => {
      vi.mocked(generateText).mockRejectedValue(new Error('API down'));

      const result = await service.analyzeUserSentiment('relaxing coding music');

      expect(result).toEqual(['relaxing', 'coding', 'music']);
    });
  });
});

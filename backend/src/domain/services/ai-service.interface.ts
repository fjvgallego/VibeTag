import { SongMetadata } from '../value-objects/song-metadata.vo';

export interface IAIService {
  getVibesForSong(song: SongMetadata): Promise<{ name: string; description: string }[]>;
  analyzeUserSentiment(prompt: string): Promise<string[]>;
}

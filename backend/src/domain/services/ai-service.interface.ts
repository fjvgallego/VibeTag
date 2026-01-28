import { SongMetadata } from '../value-objects/song-metadata';

export interface IAIService {
  getVibesForSong(song: SongMetadata): Promise<string[]>;
}

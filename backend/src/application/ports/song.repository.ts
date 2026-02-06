import { Song } from '../../domain/entities/song';

export interface UserSongData {
  id: string; // Apple Music ID for now. A future generic id will be used.
  appleMusicId?: string;
  tags: string[];
}

export interface ISongRepository {
  findUserLibrary(
    userId: string,
    options?: { page: number; limit: number },
  ): Promise<UserSongData[]>;
  findSongsByTags(tags: string[], userId: string, limit?: number): Promise<Song[]>;
}

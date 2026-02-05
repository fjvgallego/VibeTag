import { Song } from '../../domain/entities/song';

export interface UserSongData {
  id: string; // Apple Music ID
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

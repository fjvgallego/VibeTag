import { Analysis } from '../../domain/entities/analysis';
import { UserId } from '../../domain/value-objects/ids/user-id.vo';

export interface IAnalysisRepository {
  findBySong(
    title: string,
    artist: string,
    userId?: string,
    songId?: string,
  ): Promise<Analysis | null>;
  save(analysis: Analysis, userId?: string): Promise<void>;
  updateSongTags(
    userId: UserId,
    songId: string,
    tags: string[],
    metadata: {
      title: string;
      artist: string;
      appleMusicId?: string;
      album?: string;
      genre?: string;
      artworkUrl?: string;
    },
  ): Promise<void>;
}

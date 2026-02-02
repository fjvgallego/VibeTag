import { Analysis } from '../../domain/entities/analysis';
import { UserId } from '../../domain/value-objects/ids/user-id.vo';

export interface IAnalysisRepository {
  findBySong(title: string, artist: string, userId?: string, songId?: string): Promise<Analysis | null>;
  save(analysis: Analysis): Promise<void>;
  updateSongTags(userId: UserId, songId: string, tags: string[]): Promise<void>;
}

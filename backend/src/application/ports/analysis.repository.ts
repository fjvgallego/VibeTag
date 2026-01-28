import { Analysis } from '../../domain/entities/analysis';

export interface IAnalysisRepository {
  findBySong(title: string, artist: string): Promise<Analysis | null>;
  save(analysis: Analysis): Promise<void>;
}

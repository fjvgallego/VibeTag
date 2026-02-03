import { randomUUID } from 'crypto';
import { SongMetadata } from '../value-objects/song-metadata.vo';
import { VTDate } from '../value-objects/vt-date.vo';
import { VibeTag } from './vibe-tag';
import { AnalysisId } from '../value-objects/ids/analysis-id.vo';
import { SongId } from '../value-objects/ids/song-id.vo';

export class Analysis {
  public readonly id: AnalysisId;
  public readonly songId: SongId;
  public readonly songMetadata: SongMetadata;
  public readonly tags: VibeTag[];
  public readonly createdAt: VTDate;

  private constructor(
    songMetadata: SongMetadata,
    tags: VibeTag[],
    createdAt: VTDate,
    songId: SongId,
    id?: AnalysisId,
  ) {
    this.id = id || AnalysisId.create(randomUUID());
    this.songId = songId;
    this.songMetadata = songMetadata;
    this.tags = tags;
    this.createdAt = createdAt;
  }

  public static create(
    songMetadata: SongMetadata,
    tags: VibeTag[],
    createdAt: VTDate,
    songId: string,
    id?: string,
  ): Analysis {
    const analysisId = id ? AnalysisId.create(id) : undefined;
    const sId = SongId.create(songId);
    return new Analysis(songMetadata, tags, createdAt, sId, analysisId);
  }
}

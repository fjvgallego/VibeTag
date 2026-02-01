import { randomUUID } from 'crypto';
import { SongMetadata } from '../value-objects/song-metadata.vo';
import { VTDate } from '../value-objects/vt-date.vo';
import { VibeTag } from './vibe-tag';
import { AnalysisId } from '../value-objects/ids/analysis-id.vo';

export class Analysis {
  public readonly id: AnalysisId;
  public readonly songMetadata: SongMetadata;
  public readonly tags: VibeTag[];
  public readonly createdAt: VTDate;

  private constructor(
    songMetadata: SongMetadata,
    tags: VibeTag[],
    createdAt: VTDate,
    id?: AnalysisId,
  ) {
    this.id = id || AnalysisId.create(randomUUID());
    this.songMetadata = songMetadata;
    this.tags = tags;
    this.createdAt = createdAt;
  }

  public static create(
    songMetadata: SongMetadata,
    tags: VibeTag[],
    createdAt: VTDate,
    id?: string,
  ): Analysis {
    const analysisId = id ? AnalysisId.create(id) : undefined;
    return new Analysis(songMetadata, tags, createdAt, analysisId);
  }
}

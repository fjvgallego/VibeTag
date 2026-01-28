import { randomUUID } from 'crypto';
import { SongMetadata } from '../value-objects/song-metadata';
import { VibeTag } from './vibe-tag';

export class Analysis {
  public readonly id: string;
  public readonly songMetadata: SongMetadata;
  public readonly tags: VibeTag[];
  public readonly createdAt: Date;

  private constructor(songMetadata: SongMetadata, tags: VibeTag[], createdAt: Date, id?: string) {
    this.id = id || randomUUID();
    this.songMetadata = songMetadata;
    this.tags = tags;
    this.createdAt = createdAt;
  }

  public static create(
    songMetadata: SongMetadata,
    tags: VibeTag[],
    createdAt: Date,
    id?: string,
  ): Analysis {
    return new Analysis(songMetadata, tags, createdAt, id);
  }
}

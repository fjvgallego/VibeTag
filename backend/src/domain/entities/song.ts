import { SongId } from '../value-objects/ids/song-id.vo';
import { SongMetadata } from '../value-objects/song-metadata.vo';
import { VibeTag } from './vibe-tag';

export class Song {
  constructor(
    public readonly id: SongId,
    public readonly metadata: SongMetadata,
    public readonly tags: VibeTag[] = [],
    public readonly createdAt: Date = new Date(),
  ) {}

  public static create(
    id: string,
    title: string,
    artist: string,
    tags: VibeTag[] = [],
    createdAt?: Date,
    album?: string,
    genre?: string,
    artworkUrl?: string,
  ): Song {
    const songId = SongId.create(id);
    const metadata = SongMetadata.create(title, artist, album, genre, artworkUrl);
    return new Song(songId, metadata, tags, createdAt ?? new Date());
  }
}

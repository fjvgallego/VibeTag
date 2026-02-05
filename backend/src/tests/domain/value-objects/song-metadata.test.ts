import { describe, it, expect } from 'vitest';
import { SongMetadata } from '../../../domain/value-objects/song-metadata.vo';

describe('SongMetadata Value Object', () => {
  it('should create a valid SongMetadata with all fields', () => {
    const metadata = SongMetadata.create({
      title: 'Title',
      artist: 'Artist',
      album: 'Album',
      genre: 'Genre',
    });
    expect(metadata).toBeInstanceOf(SongMetadata);
    expect(metadata.title).toBe('Title');
    expect(metadata.artist).toBe('Artist');
    expect(metadata.album).toBe('Album');
    expect(metadata.genre).toBe('Genre');
  });

  it('should create a valid SongMetadata without album and genre', () => {
    const metadata = SongMetadata.create({ title: 'Title', artist: 'Artist' });
    expect(metadata).toBeInstanceOf(SongMetadata);
    expect(metadata.title).toBe('Title');
    expect(metadata.artist).toBe('Artist');
    expect(metadata.album).toBeUndefined();
    expect(metadata.genre).toBeUndefined();
  });

  it('should implement equality check correctly', () => {
    const metadataA = SongMetadata.create({ title: 'Title', artist: 'Artist', album: 'Album' });
    const metadataB = SongMetadata.create({ title: 'Title', artist: 'Artist', album: 'Album' });
    const metadataC = SongMetadata.create({ title: 'Title', artist: 'Artist' });

    expect(metadataA.equals(metadataB)).toBe(true);
    expect(metadataA.equals(metadataC)).toBe(false);
  });
});

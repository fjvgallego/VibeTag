import { describe, it, expect } from 'vitest';
import { Song } from '../../../domain/entities/song';
import { VibeTag } from '../../../domain/entities/vibe-tag';
import { SongId } from '../../../domain/value-objects/ids/song-id.vo';

describe('Song Entity', () => {
  it('should create a Song with required fields', () => {
    const song = Song.create('song-1', 'Starboy', 'The Weeknd');

    expect(song).toBeInstanceOf(Song);
    expect(song.id).toBeInstanceOf(SongId);
    expect(song.id.value).toBe('song-1');
    expect(song.metadata.title).toBe('Starboy');
    expect(song.metadata.artist).toBe('The Weeknd');
    expect(song.tags).toEqual([]);
    expect(song.createdAt).toBeInstanceOf(Date);
  });

  it('should create a Song with tags', () => {
    const tags = [VibeTag.create('Chill', 'ai'), VibeTag.create('Dreamy', 'user')];
    const song = Song.create('song-2', 'Blinding Lights', 'The Weeknd', tags);

    expect(song.tags).toHaveLength(2);
    expect(song.tags[0].name).toBe('chill');
    expect(song.tags[1].name).toBe('dreamy');
  });

  it('should create a Song with optional metadata', () => {
    const song = Song.create(
      'song-3',
      'Save Your Tears',
      'The Weeknd',
      [],
      new Date('2025-01-01'),
      'apple-123',
      'After Hours',
      'Pop',
      'https://example.com/artwork.jpg',
    );

    expect(song.metadata.album).toBe('After Hours');
    expect(song.metadata.genre).toBe('Pop');
    expect(song.metadata.appleMusicId).toBe('apple-123');
    expect(song.metadata.artworkUrl).toBe('https://example.com/artwork.jpg');
    expect(song.createdAt).toEqual(new Date('2025-01-01'));
  });

  it('should default createdAt to current date', () => {
    const before = new Date();
    const song = Song.create('song-4', 'Title', 'Artist');
    const after = new Date();

    expect(song.createdAt.getTime()).toBeGreaterThanOrEqual(before.getTime());
    expect(song.createdAt.getTime()).toBeLessThanOrEqual(after.getTime());
  });
});

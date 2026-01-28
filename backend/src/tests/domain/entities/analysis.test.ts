import { describe, it, expect } from 'vitest';
import { Analysis } from '../../../domain/entities/analysis';
import { SongMetadata } from '../../../domain/value-objects/song-metadata';
import { VibeTag } from '../../../domain/entities/vibe-tag';

describe('Analysis Entity', () => {
  const metadata = SongMetadata.create('Title', 'Artist');
  const tags = [VibeTag.create('chill', 'ai')];
  const now = new Date();

  it('should create a valid Analysis', () => {
    const analysis = Analysis.create(metadata, tags, now);
    expect(analysis).toBeInstanceOf(Analysis);
    expect(analysis.songMetadata).toBe(metadata);
    expect(analysis.tags).toEqual(tags);
    expect(analysis.createdAt).toBe(now);
    expect(analysis.id).toBeDefined();
  });

  it('should generate a valid UUID if no ID is provided', () => {
    const analysis = Analysis.create(metadata, tags, now);
    expect(analysis.id).toBeTypeOf('string');
    expect(analysis.id.length).toBeGreaterThan(0);
    expect(analysis.id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
  });

  it('should preserve provided ID if supplied', () => {
    const existingId = 'existing-uuid';
    const analysis = Analysis.create(metadata, tags, now, existingId);
    expect(analysis.id).toBe(existingId);
  });
});

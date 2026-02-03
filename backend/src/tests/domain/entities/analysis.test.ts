import { describe, it, expect } from 'vitest';
import { Analysis } from '../../../domain/entities/analysis';
import { SongMetadata } from '../../../domain/value-objects/song-metadata.vo';
import { VibeTag } from '../../../domain/entities/vibe-tag';
import { VTDate } from '../../../domain/value-objects/vt-date.vo';
import { AnalysisId } from '../../../domain/value-objects/ids/analysis-id.vo';

describe('Analysis Entity', () => {
  const metadata = SongMetadata.create('Title', 'Artist');
  const tags = [VibeTag.create('chill', 'ai')];
  const now = VTDate.now();

  it('should create a valid Analysis', () => {
    const analysis = Analysis.create(metadata, tags, now, 'song-123');
    expect(analysis).toBeInstanceOf(Analysis);
    expect(analysis.songMetadata).toBe(metadata);
    expect(analysis.tags).toEqual(tags);
    expect(analysis.createdAt.equals(now)).toBe(true);
    expect(analysis.id).toBeInstanceOf(AnalysisId);
    expect(analysis.songId.value).toBe('song-123');
  });

  it('should generate a valid UUID if no ID is provided', () => {
    const analysis = Analysis.create(metadata, tags, now, 'song-123');
    expect(analysis.id.value).toBeTypeOf('string');
    expect(analysis.id.value.length).toBeGreaterThan(0);
    expect(analysis.id.value).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
    );
  });

  it('should preserve provided ID if supplied', () => {
    const existingId = 'existing-uuid';
    const analysis = Analysis.create(metadata, tags, now, 'song-123', existingId);
    expect(analysis.id.value).toBe(existingId);
  });
});

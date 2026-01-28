import { describe, it, expect } from 'vitest';
import { VibeTag } from '../../../domain/entities/vibe-tag';

describe('VibeTag Entity', () => {
  it('should create a valid VibeTag', () => {
    const tag = VibeTag.create('chill', 'ai');
    expect(tag).toBeInstanceOf(VibeTag);
    expect(tag.name).toBe('chill');
    expect(tag.source).toBe('ai');
    expect(tag.id).toBeDefined();
  });

  it('should normalize tag name to lowercase', () => {
    const tag = VibeTag.create('CHILL', 'ai');
    expect(tag.name).toBe('chill');
  });

  it('should normalize mixed case tag name to lowercase', () => {
    const tag = VibeTag.create('ChIlL ViBeS', 'user');
    expect(tag.name).toBe('chill vibes');
  });

  it('should preserve provided ID if supplied', () => {
    const existingId = '123-abc';
    const tag = VibeTag.create('chill', 'ai', existingId);
    expect(tag.id).toBe(existingId);
  });
});

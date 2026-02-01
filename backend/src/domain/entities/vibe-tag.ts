import { ValidationError } from '../errors/app-error';
import { randomUUID } from 'crypto';
import { VibeTagId } from '../value-objects/ids/vibe-tag-id.vo';

export type VibeTagSource = 'ai' | 'user';

export class VibeTag {
  public readonly id: VibeTagId;
  public readonly name: string;
  public readonly source: VibeTagSource;

  private constructor(name: string, source: VibeTagSource, id?: VibeTagId) {
    this.id = id || VibeTagId.create(randomUUID());
    this.name = name.toLowerCase();
    this.source = source;
  }

  public static create(name: string, source: VibeTagSource, id?: string): VibeTag {
    if (!name || name.trim().length === 0) {
      throw new ValidationError('VibeTag name cannot be empty');
    }
    const tagId = id ? VibeTagId.create(id) : undefined;
    return new VibeTag(name.trim(), source, tagId);
  }
}

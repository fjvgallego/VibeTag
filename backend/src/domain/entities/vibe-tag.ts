import { randomUUID } from 'crypto';

export type VibeTagSource = 'ai' | 'user';

export class VibeTag {
  public readonly id: string;
  public readonly name: string;
  public readonly source: VibeTagSource;

  private constructor(name: string, source: VibeTagSource, id?: string) {
    this.id = id || randomUUID();
    this.name = name.toLowerCase();
    this.source = source;
  }

  public static create(name: string, source: VibeTagSource, id?: string): VibeTag {
    return new VibeTag(name, source, id);
  }
}

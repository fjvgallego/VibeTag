import { ValidationError } from '../../errors/app-error';

export class SongId {
  public readonly value: string;

  private constructor(value: string) {
    this.value = value;
  }

  public static create(id: string): SongId {
    if (!id || id.trim().length === 0) {
      throw new ValidationError('Song ID cannot be empty');
    }

    return new SongId(id.trim());
  }

  public equals(other: SongId): boolean {
    if (!(other instanceof SongId)) {
      return false;
    }
    return this.value === other.value;
  }
}

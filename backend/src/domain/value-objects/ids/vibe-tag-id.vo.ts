import { ValidationError } from '../../errors/app-error';

export class VibeTagId {
  public readonly value: string;

  private constructor(value: string) {
    this.value = value;
  }

  public static create(id: string): VibeTagId {
    if (!id || id.trim().length === 0) {
      throw new ValidationError('VibeTag ID cannot be empty');
    }

    return new VibeTagId(id.trim());
  }

  public equals(other: VibeTagId): boolean {
    if (!(other instanceof VibeTagId)) {
      return false;
    }
    return this.value === other.value;
  }
}

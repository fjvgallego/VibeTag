import { ValidationError } from '../../errors/app-error';

export class AppleId {
  public readonly value: string;

  private constructor(value: string) {
    this.value = value;
  }

  public static create(appleId: string): AppleId {
    if (!appleId || appleId.trim().length === 0) {
      throw new ValidationError('User must have a valid Apple ID');
    }

    return new AppleId(appleId.trim());
  }

  public equals(other: AppleId): boolean {
    if (!(other instanceof AppleId)) {
      return false;
    }
    return this.value === other.value;
  }
}

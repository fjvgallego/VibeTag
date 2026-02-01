import { ValidationError } from '../../errors/app-error';

export class UserId {
  public readonly value: string;

  private constructor(value: string) {
    this.value = value;
  }

  public static create(id: string): UserId {
    if (!id || id.trim().length === 0) {
      throw new ValidationError('User ID cannot be empty');
    }

    return new UserId(id.trim());
  }

  public equals(other: UserId): boolean {
    if (!(other instanceof UserId)) {
      return false;
    }
    return this.value === other.value;
  }
}

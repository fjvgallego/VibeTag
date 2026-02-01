import { ValidationError } from '../errors/app-error';

export class Email {
  public readonly value: string;

  private constructor(value: string) {
    this.value = value;
  }

  public static create(email: string): Email {
    if (!email) {
      throw new ValidationError('Email is required');
    }

    const trimmedEmail = email.trim().toLowerCase();
    // Basic email validation regex
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(trimmedEmail)) {
      throw new ValidationError('Invalid email format');
    }

    return new Email(trimmedEmail);
  }

  public equals(other: Email): boolean {
    if (!(other instanceof Email)) {
      return false;
    }
    return this.value === other.value;
  }
}

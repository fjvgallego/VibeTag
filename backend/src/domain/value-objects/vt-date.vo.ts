import { ValidationError } from '../errors/app-error';

export class VTDate {
  public readonly value: string;

  private constructor(value: string) {
    this.value = value;
  }

  public static create(date: Date | string): VTDate {
    if (!date) {
      throw new ValidationError('Date is required');
    }

    let dateStr: string;

    if (date instanceof Date) {
      dateStr = date.toISOString();
    } else {
      if (typeof date !== 'string') {
        throw new ValidationError('Invalid date format');
      }
      const trimmedDate = date.trim();
      if (!this.isValidISODate(trimmedDate)) {
        throw new ValidationError(`Invalid ISO Date format: ${trimmedDate}`);
      }
      dateStr = trimmedDate;
    }

    return new VTDate(dateStr);
  }

  public static now(): VTDate {
    return new VTDate(new Date().toISOString());
  }

  private static isValidISODate(dateString: string): boolean {
    // Check if it's a valid date object first
    const date = new Date(dateString);
    if (isNaN(date.getTime())) {
      return false;
    }

    const isoRegex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,3})?(Z|[+-]\d{2}:\d{2})$/;
    return isoRegex.test(dateString);
  }

  public equals(other: VTDate): boolean {
    if (!(other instanceof VTDate)) {
      return false;
    }
    return this.value === other.value;
  }
}

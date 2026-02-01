import { ValidationError } from '../../errors/app-error';

export class AnalysisId {
  public readonly value: string;

  private constructor(value: string) {
    this.value = value;
  }

  public static create(id: string): AnalysisId {
    if (!id || id.trim().length === 0) {
      throw new ValidationError('Analysis ID cannot be empty');
    }

    return new AnalysisId(id.trim());
  }

  public equals(other: AnalysisId): boolean {
    if (!(other instanceof AnalysisId)) {
      return false;
    }
    return this.value === other.value;
  }
}

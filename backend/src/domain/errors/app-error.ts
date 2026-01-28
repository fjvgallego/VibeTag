export abstract class AppError extends Error {
  constructor(message: string) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class RepositoryError extends AppError {
  constructor(message: string = 'A repository error occurred') {
    super(message);
  }
}

export class UseCaseError extends AppError {
  constructor(message: string = 'A use case error occurred') {
    super(message);
  }
}

export class ValidationError extends AppError {
  constructor(message: string = 'Validation failed') {
    super(message);
  }
}

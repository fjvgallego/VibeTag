export abstract class AppError extends Error {
  public readonly cause?: Error;

  constructor(message: string, options?: { cause?: Error }) {
    super(message);
    this.name = this.constructor.name;
    this.cause = options?.cause;

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

export class RepositoryError extends AppError {
  constructor(message: string = 'A repository error occurred', options?: { cause?: Error }) {
    super(message, options);
  }
}

export class UseCaseError extends AppError {
  constructor(message: string = 'A use case error occurred', options?: { cause?: Error }) {
    super(message, options);
  }
}

export class ValidationError extends AppError {
  constructor(message: string = 'Validation failed', options?: { cause?: Error }) {
    super(message, options);
  }
}

export class AuthError extends AppError {
  constructor(message: string = 'Authentication failed', options?: { cause?: Error }) {
    super(message, options);
  }
}

export class UserNotFoundError extends AppError {
  constructor(message: string = 'User not found', options?: { cause?: Error }) {
    super(message, options);
  }
}

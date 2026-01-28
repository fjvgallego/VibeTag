export class Result<T, E> {
  public readonly success: boolean;
  public readonly isFailure: boolean;
  public readonly data?: T;
  public readonly error?: E;

  private constructor(success: boolean, data?: T, error?: E) {
    if (success && error !== undefined) {
      throw new Error('InvalidOperation: A result cannot be successful and contain an error');
    }
    if (!success && error === undefined) {
      throw new Error('InvalidOperation: A failing result needs to contain an error');
    }

    this.success = success;
    this.isFailure = !success;
    this.data = data;
    this.error = error;
  }

  public static ok<T, E>(data: T): Result<T, E> {
    return new Result<T, E>(true, data);
  }

  public static fail<T, E>(error: E): Result<T, E> {
    return new Result<T, E>(false, undefined, error);
  }

  public getValue(): T {
    if (!this.success) {
      throw new Error('Cannot get value of a failed result.');
    }
    return this.data as T;
  }

  public getError(): E {
    if (this.success) {
      throw new Error('Cannot get error of a successful result.');
    }
    return this.error as E;
  }
}

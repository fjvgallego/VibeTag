import { Result } from '../../shared/result';
import { AppError } from '../../domain/errors/app-error';

export interface UseCase<IRequest, IResponse, IError = AppError> {
  execute(request?: IRequest): Promise<Result<IResponse, IError>> | Result<IResponse, IError>;
}

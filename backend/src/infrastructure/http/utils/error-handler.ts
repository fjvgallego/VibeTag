import { Response } from 'express';
import {
  AppError,
  AuthError,
  UserNotFoundError,
  ValidationError,
} from '../../../domain/errors/app-error';

export class ErrorHandler {
  public static handle(res: Response, error: unknown): void {
    if (error instanceof ValidationError) {
      res.status(400).json({ error: error.message }); // ValidationError messages are typically safe
      return;
    }

    if (error instanceof AuthError) {
      res.status(401).json({ error: 'Authentication failed' }); // Use generic message
      return;
    }

    if (error instanceof UserNotFoundError) {
      res.status(404).json({ error: 'Resource not found' }); // Avoid revealing entity types
      return;
    }

    if (error instanceof AppError) {
      res.status(400).json({ error: 'Bad request' }); // Use generic message for other AppErrors
      return;
    }

    console.error('Unexpected error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

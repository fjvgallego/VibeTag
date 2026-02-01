import { Request, Response } from 'express';
import { AnalyzeUseCase } from '../../../application/use-cases/analyze.use-case';
import { ValidationError } from '../../../domain/errors/app-error';

export class AnalyzeController {
  constructor(private readonly analyzeUseCase: AnalyzeUseCase) {}

  public async analyze(req: Request, res: Response): Promise<Response> {
    try {
      const result = await this.analyzeUseCase.execute(req.body);

      if (result.success) {
        return res.json(result.data);
      }

      // Map known errors
      const err = result.error;
      if (err instanceof ValidationError) {
        return res.status(400).json({ message: err.message });
      }

      return res.status(500).json({
        message: 'Internal server error',
      });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ message: 'Unexpected error' });
    }
  }
}

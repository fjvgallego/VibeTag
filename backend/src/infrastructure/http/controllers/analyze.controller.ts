import { Request, Response } from 'express';
import { AnalyzeUseCase } from '../../../application/use-cases/analyze.use-case';
import { ErrorHandler } from '../utils/error-handler';

export class AnalyzeController {
  constructor(private readonly analyzeUseCase: AnalyzeUseCase) {}

  public async analyze(req: Request, res: Response): Promise<Response> {
    try {
      const userId = req.user?.userId;

      if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const { songId, title, artist, album, genre, artworkUrl } = req.body;

      const result = await this.analyzeUseCase.execute({
        songId,
        title,
        artist,
        album,
        genre,
        artworkUrl,
        userId,
      });

      if (result.success) {
        return res.json(result.data);
      }

      ErrorHandler.handle(res, result.error);
      return res;
    } catch (e) {
      ErrorHandler.handle(res, e);
      return res;
    }
  }

  public async analyzeBatch(req: Request, res: Response): Promise<Response> {
    try {
      const userId = req.user?.userId;

      if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const { songs } = req.body;

      if (!Array.isArray(songs)) {
        return res.status(400).json({ message: 'Songs must be an array' });
      }

      const result = await this.analyzeUseCase.executeBatch({
        songs,
        userId,
      });

      if (result.success) {
        return res.json(result.data);
      }

      ErrorHandler.handle(res, result.error);
      return res;
    } catch (e) {
      ErrorHandler.handle(res, e);
      return res;
    }
  }
}

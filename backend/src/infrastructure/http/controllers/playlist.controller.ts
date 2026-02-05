import { Request, Response } from 'express';
import { GeneratePlaylistUseCase } from '../../../application/use-cases/generate-playlist.use-case';
import { AppError } from '../../../domain/errors/app-error';

export class PlaylistController {
  constructor(private readonly generatePlaylistUseCase: GeneratePlaylistUseCase) {}

  public async generate(req: Request, res: Response): Promise<void> {
    const userId = req.user?.userId;
    const { prompt } = req.body;

    if (!userId) {
      res.status(401).json({ error: 'User not authenticated' });
      return;
    }

    if (!prompt || typeof prompt !== 'string') {
      res.status(400).json({ error: 'Prompt is required and must be a string' });
      return;
    }

    const result = await this.generatePlaylistUseCase.execute({
      userId,
      userPrompt: prompt,
    });

    if (result.isFailure) {
      const error = result.getError();
      const statusCode = error instanceof AppError ? 400 : 500;
      res.status(statusCode).json({ error: error.message });
      return;
    }

    res.status(200).json(result.getValue());
  }
}

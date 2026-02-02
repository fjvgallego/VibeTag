import { Request, Response } from 'express';
import { UpdateSongTagsUseCase } from '../../../application/use-cases/update-song-tags.use-case';
import { GetUserLibraryUseCase } from '../../../application/use-cases/get-user-library.use-case';
import { AppError } from '../../../domain/errors/app-error';

export class SongController {
  constructor(
    private readonly updateSongTagsUseCase: UpdateSongTagsUseCase,
    private readonly getUserLibraryUseCase: GetUserLibraryUseCase
  ) {}

  public async getSyncedSongs(req: Request, res: Response): Promise<void> {
    const userId = req.user?.userId;

    if (!userId) {
      res.status(401).json({ error: 'User not authenticated' });
      return;
    }

    const result = await this.getUserLibraryUseCase.execute(userId);

    if (result.isFailure) {
      const error = result.getError();
      const statusCode = error instanceof AppError ? 400 : 500;
      res.status(statusCode).json({ error: error.message });
      return;
    }

    res.status(200).json(result.getValue());
  }

  public async updateTags(req: Request, res: Response): Promise<void> {
    const songId = req.params.id as string;
    const { tags } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      res.status(401).json({ error: 'User not authenticated' });
      return;
    }

    const result = await this.updateSongTagsUseCase.execute({
      userId,
      songId,
      tags,
    });

    if (result.isFailure) {
      const error = result.getError();
      const statusCode = error instanceof AppError ? 400 : 500;
      res.status(statusCode).json({ error: error.message });
      return;
    }

    res.status(200).json({ message: 'Song tags updated successfully' });
  }
}

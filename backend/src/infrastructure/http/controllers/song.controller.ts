import { Request, Response } from 'express';
import { UpdateSongTagsUseCase } from '../../../application/use-cases/update-song-tags.use-case';
import { GetUserLibraryUseCase } from '../../../application/use-cases/get-user-library.use-case';
import { AppError } from '../../../domain/errors/app-error';

export class SongController {
  constructor(
    private readonly updateSongTagsUseCase: UpdateSongTagsUseCase,
    private readonly getUserLibraryUseCase: GetUserLibraryUseCase,
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
    const songId = req.params.id;
    const { tags, title, artist } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      res.status(401).json({ error: 'User not authenticated' });
      return;
    }

    if (!songId || typeof songId !== 'string') {
      res.status(400).json({ error: 'Invalid song ID' });
      return;
    }

    if (!Array.isArray(tags) || !tags.every((t) => typeof t === 'string')) {
      res.status(400).json({ error: 'Tags must be an array of strings' });
      return;
    }

    if (!title || typeof title !== 'string') {
      res.status(400).json({ error: 'Title is required and must be a string' });
      return;
    }

    if (!artist || typeof artist !== 'string') {
      res.status(400).json({ error: 'Artist is required and must be a string' });
      return;
    }

    const result = await this.updateSongTagsUseCase.execute({
      userId,
      songId,
      tags,
      title,
      artist,
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

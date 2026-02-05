import { Request, Response } from 'express';
import { UpdateSongTagsUseCase } from '../../../application/use-cases/update-song-tags.use-case';
import { GetUserLibraryUseCase } from '../../../application/use-cases/get-user-library.use-case';
import { ErrorHandler } from '../utils/error-handler';

export class SongController {
  constructor(
    private readonly updateSongTagsUseCase: UpdateSongTagsUseCase,
    private readonly getUserLibraryUseCase: GetUserLibraryUseCase,
  ) {}

  public async getSyncedSongs(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.userId;

      if (!userId) {
        res.status(401).json({ error: 'User not authenticated' });
        return;
      }

      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 50;

      if (page < 1) {
        res.status(400).json({ error: 'Page must be a positive integer' });
        return;
      }

      if (limit < 1 || limit > 100) {
        res.status(400).json({ error: 'Limit must be between 1 and 100' });
        return;
      }

      const result = await this.getUserLibraryUseCase.execute(userId, page, limit);

      if (result.isFailure) {
        ErrorHandler.handle(res, result.getError());
        return;
      }

      res.status(200).json(result.getValue());
    } catch (error) {
      ErrorHandler.handle(res, error);
    }
  }

  public async updateTags(req: Request, res: Response): Promise<void> {
    try {
      const songId = req.params.id;
      const { tags, title, artist, album, genre, artworkUrl } = req.body;
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
        album,
        genre,
        artworkUrl,
      });

      if (result.isFailure) {
        ErrorHandler.handle(res, result.getError());
        return;
      }

      res.status(200).json({ message: 'Song tags updated successfully' });
    } catch (error) {
      ErrorHandler.handle(res, error);
    }
  }
}

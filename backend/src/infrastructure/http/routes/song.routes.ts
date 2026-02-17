import { Router, RequestHandler } from 'express';
import { SongController } from '../controllers/song.controller';

export function createSongRouter(
  songController: SongController,
  verifyToken: RequestHandler,
): Router {
  const router = Router();

  router.get('/synced', verifyToken, (req, res) => songController.getSyncedSongs(req, res));
  router.patch('/:id', verifyToken, (req, res) => songController.updateTags(req, res));

  return router;
}

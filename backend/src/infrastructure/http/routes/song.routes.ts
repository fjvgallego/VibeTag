import { Router } from 'express';
import { SongController } from '../controllers/song.controller';
import { verifyToken } from '../middleware/AuthMiddleware';

export function createSongRouter(songController: SongController): Router {
  const router = Router();

  router.get('/synced', verifyToken, (req, res) => songController.getSyncedSongs(req, res));
  router.patch('/:id', verifyToken, (req, res) => songController.updateTags(req, res));

  return router;
}

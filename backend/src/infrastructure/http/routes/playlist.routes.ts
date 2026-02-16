import { Router } from 'express';
import { PlaylistController } from '../controllers/playlist.controller';
import { verifyToken } from '../middleware/AuthMiddleware';

export function createPlaylistRouter(playlistController: PlaylistController): Router {
  const router = Router();

  router.post('/generate', verifyToken, (req, res) => playlistController.generate(req, res));

  return router;
}

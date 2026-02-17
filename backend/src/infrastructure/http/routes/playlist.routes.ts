import { Router, RequestHandler } from 'express';
import { PlaylistController } from '../controllers/playlist.controller';

export function createPlaylistRouter(
  playlistController: PlaylistController,
  verifyToken: RequestHandler,
): Router {
  const router = Router();

  router.post('/generate', verifyToken, (req, res) => playlistController.generate(req, res));

  return router;
}

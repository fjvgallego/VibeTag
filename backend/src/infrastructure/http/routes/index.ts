import { Router } from 'express';
import { Dependencies } from '../../../composition/containers/container';
import { AnalyzeController } from '../controllers/analyze.controller';
import { AuthController } from '../controllers/auth.controller';
import { SongController } from '../controllers/song.controller';
import { PlaylistController } from '../controllers/playlist.controller';
import { createAnalyzeRouter } from './analyze.routes';
import { createAuthRouter } from './auth.routes';
import { createSongRouter } from './song.routes';
import { createPlaylistRouter } from './playlist.routes';
import { createVerifyToken } from '../middleware/auth-middleware';

export function createAppRouter(container: Dependencies): Router {
  const router = Router();

  // Create middleware from injected token service
  const verifyToken = createVerifyToken(container.tokenService);

  // Instantiate controllers
  const analyzeController = new AnalyzeController(container.analyzeUseCase);
  const authController = new AuthController(
    container.loginWithAppleUseCase,
    container.deleteAccountUseCase,
  );
  const songController = new SongController(
    container.updateSongTagsUseCase,
    container.getUserLibraryUseCase,
  );
  const playlistController = new PlaylistController(container.generatePlaylistUseCase);

  // Register routes
  const apiV1Router = Router();
  apiV1Router.use('/analyze', createAnalyzeRouter(analyzeController, verifyToken));
  apiV1Router.use('/auth', createAuthRouter(authController, verifyToken));
  apiV1Router.use('/songs', createSongRouter(songController, verifyToken));
  apiV1Router.use('/playlists', createPlaylistRouter(playlistController, verifyToken));

  router.use('/api/v1', apiV1Router);

  return router;
}

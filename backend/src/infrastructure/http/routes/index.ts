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

export function createAppRouter(container: Dependencies): Router {
  const router = Router();

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
  apiV1Router.use('/analyze', createAnalyzeRouter(analyzeController));
  apiV1Router.use('/auth', createAuthRouter(authController));
  apiV1Router.use('/songs', createSongRouter(songController));
  apiV1Router.use('/playlists', createPlaylistRouter(playlistController));

  router.use('/api/v1', apiV1Router);

  return router;
}

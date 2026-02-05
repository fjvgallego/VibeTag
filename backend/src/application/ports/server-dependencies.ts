import { AnalyzeUseCase } from '../use-cases/analyze.use-case';
import { UpdateSongTagsUseCase } from '../use-cases/update-song-tags.use-case';
import { GetUserLibraryUseCase } from '../use-cases/get-user-library.use-case';
import { GeneratePlaylistUseCase } from '../use-cases/generate-playlist.use-case';

export interface ServerDependencies {
  analyzeUseCase: AnalyzeUseCase;
  updateSongTagsUseCase: UpdateSongTagsUseCase;
  getUserLibraryUseCase: GetUserLibraryUseCase;
  generatePlaylistUseCase: GeneratePlaylistUseCase;
}

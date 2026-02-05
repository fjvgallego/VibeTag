import { SongDTO } from './song.dto';

export interface GeneratePlaylistRequestDTO {
  userId: string;
  userPrompt: string;
}

export interface GeneratePlaylistResponseDTO {
  playlistTitle: string;
  description: string;
  usedTags: string[];
  songs: SongDTO[];
}

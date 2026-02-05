export interface UpdateSongTagsDTO {
  tags: string[];
  title: string;
  artist: string;
}

export interface UserSongLibraryDTO {
  id: string;
  tags: string[];
}

export interface SongDTO {
  id: string;
  title: string;
  artist: string;
  tags: string[];
}

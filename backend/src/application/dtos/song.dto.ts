export interface UpdateSongTagsDTO {
  tags: string[];
  title: string;
  artist: string;
  appleMusicId?: string;
  album?: string;
  genre?: string;
  artworkUrl?: string;
}

export interface UserSongLibraryDTO {
  id: string;
  appleMusicId?: string;
  tags: string[];
}

export interface SongDTO {
  id: string;
  title: string;
  artist: string;
  appleMusicId?: string;
  album?: string;
  genre?: string;
  tags: string[];
}

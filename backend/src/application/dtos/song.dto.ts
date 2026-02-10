export interface TagDTO {
  name: string;
  type: 'SYSTEM' | 'USER';
}

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
  tags: TagDTO[];
}

export interface SongDTO {
  id: string;
  title: string;
  artist: string;
  appleMusicId?: string;
  album?: string;
  genre?: string;
  tags: TagDTO[];
}

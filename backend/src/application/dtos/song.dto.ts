export interface TagDTO {
  name: string;
  type: 'SYSTEM' | 'USER';
  color?: string;
}

export interface TagUpdateDTO {
  name: string;
  color?: string;
}

export interface GetUserLibraryRequestDTO {
  userId: string;
  page: number;
  limit: number;
}

export interface UpdateSongTagsDTO {
  tags: (string | TagUpdateDTO)[];
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
  artworkUrl?: string;
  tags: TagDTO[];
}

export interface SongDTO {
  id: string;
  title: string;
  artist: string;
  appleMusicId?: string;
  artworkUrl?: string;
  album?: string;
  genre?: string;
  tags: TagDTO[];
}

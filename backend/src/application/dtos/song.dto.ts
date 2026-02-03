export interface UpdateSongTagsDTO {
  tags: string[];
  title: string;
  artist: string;
}

export interface UserSongLibraryDTO {
  id: string;
  tags: string[];
}

export interface UserSongData {
  id: string; // Apple Music ID
  tags: string[];
}

export interface ISongRepository {
  findUserLibrary(userId: string): Promise<UserSongData[]>;
}

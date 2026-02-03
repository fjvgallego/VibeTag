export interface UserSongData {
  id: string; // Apple Music ID
  tags: string[];
}

export interface ISongRepository {
  findUserLibrary(
    userId: string,
    options?: { page: number; limit: number },
  ): Promise<UserSongData[]>;
}

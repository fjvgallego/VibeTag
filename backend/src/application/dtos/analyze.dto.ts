export interface AnalyzeRequestDTO {
  songId?: string;
  appleMusicId?: string;
  title: string;
  artist: string;
  album?: string;
  genre?: string;
  artworkUrl?: string;
  userId?: string;
}

export interface AnalyzeResponseDTO {
  songId: string;
  tags: { name: string; description?: string }[];
}

export interface BatchAnalyzeRequestDTO {
  userId?: string;
  songs: {
    songId?: string;
    appleMusicId?: string;
    title: string;
    artist: string;
    album?: string;
    genre?: string;
    artworkUrl?: string;
  }[];
}

export interface BatchAnalyzeResponseDTO {
  results: {
    songId?: string;
    title: string;
    tags: { name: string; description?: string }[];
    error?: string;
  }[];
}

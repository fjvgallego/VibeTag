export interface AnalyzeRequestDTO {
  songId?: string;
  title: string;
  artist: string;
  album?: string;
  genre?: string;
  userId?: string;
}

export interface AnalyzeResponseDTO {
  tags: { name: string; description?: string }[];
}

export interface BatchAnalyzeRequestDTO {
  userId?: string;
  songs: {
    songId?: string;
    title: string;
    artist: string;
    album?: string;
    genre?: string;
  }[];
}

export interface BatchAnalyzeResponseDTO {
  results: {
    songId?: string;
    title: string;
    tags: { name: string; description?: string }[];
  }[];
}

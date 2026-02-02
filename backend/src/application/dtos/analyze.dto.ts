export interface AnalyzeRequestDTO {
  songId?: string;
  title: string;
  artist: string;
  album?: string;
  genre?: string;
  userId?: string;
}

export interface AnalyzeResponseDTO {
  tags: string[];
}

export interface AnalyzeRequestDTO {
  title: string;
  artist: string;
  album?: string;
  genre?: string;
}

export interface AnalyzeResponseDTO {
  vibes: string[];
}

import { ValidationError } from '../errors/app-error';

export class SongMetadata {
  public readonly title: string;
  public readonly artist: string;
  public readonly album?: string;
  public readonly genre?: string;

  private constructor(title: string, artist: string, album?: string, genre?: string) {
    this.title = title;
    this.artist = artist;
    this.album = album;
    this.genre = genre;
  }

  public static create(
    title: string,
    artist: string,
    album?: string,
    genre?: string,
  ): SongMetadata {
    const t = title?.trim();
    const a = artist?.trim();

    if (!t || !a) {
      throw new ValidationError('Title and artist are required');
    }

    if (t.length > 300 || a.length > 300) {
      throw new ValidationError('Title or artist too long');
    }

    return new SongMetadata(t, a, album?.trim(), genre?.trim());
  }

  public equals(other: SongMetadata): boolean {
    if (!(other instanceof SongMetadata)) return false;
    return (
      this.title === other.title &&
      this.artist === other.artist &&
      this.album === other.album &&
      this.genre === other.genre
    );
  }
}

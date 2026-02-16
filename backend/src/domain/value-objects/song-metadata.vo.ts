import { ValidationError } from '../errors/app-error';

export interface SongMetadataProps {
  title: string;
  artist: string;
  appleMusicId?: string;
  album?: string;
  genre?: string;
  artworkUrl?: string;
}

export class SongMetadata {
  public readonly title: string;
  public readonly artist: string;
  public readonly appleMusicId?: string;
  public readonly album?: string;
  public readonly genre?: string;
  public readonly artworkUrl?: string;

  private constructor(props: SongMetadataProps) {
    this.title = props.title;
    this.artist = props.artist;
    this.appleMusicId = props.appleMusicId;
    this.album = props.album;
    this.genre = props.genre;
    this.artworkUrl = props.artworkUrl;
  }

  public static create(props: SongMetadataProps): SongMetadata {
    const t = props.title?.trim();
    const a = props.artist?.trim();

    if (!t || !a) {
      throw new ValidationError('Title and artist are required');
    }

    if (t.length > 300 || a.length > 300) {
      throw new ValidationError('Title or artist too long');
    }

    return new SongMetadata({
      ...props,
      title: t,
      artist: a,
      appleMusicId: props.appleMusicId?.trim(),
      album: props.album?.trim(),
      genre: props.genre?.trim(),
      artworkUrl: props.artworkUrl?.trim(),
    });
  }

  public equals(other: SongMetadata): boolean {
    if (!(other instanceof SongMetadata)) return false;
    return (
      this.title === other.title &&
      this.artist === other.artist &&
      this.appleMusicId === other.appleMusicId &&
      this.album === other.album &&
      this.genre === other.genre &&
      this.artworkUrl === other.artworkUrl
    );
  }
}

import {
  Song as PrismaSong,
  Tag as PrismaTag,
  SongTag as PrismaSongTag,
} from '../../../prisma/generated';
import { Song } from '../../domain/entities/song';
import { VibeTag } from '../../domain/entities/vibe-tag';

type PrismaSongWithTags = PrismaSong & {
  songTags: (PrismaSongTag & {
    tag: PrismaTag;
  })[];
};

export class SongMapper {
  public static toDomain(prismaSong: PrismaSongWithTags): Song {
    const domainTags = prismaSong.songTags.map((st) =>
      VibeTag.create(
        st.tag.name,
        st.tag.type === 'SYSTEM' ? 'ai' : 'user',
        st.tag.id,
        st.tag.description || undefined,
      ),
    );

    return Song.create(
      prismaSong.id,
      prismaSong.title,
      prismaSong.artist,
      domainTags,
      prismaSong.createdAt,
      prismaSong.appleMusicId || undefined,
      prismaSong.album || undefined,
      prismaSong.genre || undefined,
      prismaSong.artworkUrl || undefined,
    );
  }
}

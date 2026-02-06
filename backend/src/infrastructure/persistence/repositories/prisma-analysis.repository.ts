import { IAnalysisRepository } from '../../../application/ports/analysis.repository';
import { Analysis } from '../../../domain/entities/analysis';
import { SongMetadata } from '../../../domain/value-objects/song-metadata.vo';
import { VibeTag, VibeTagSource } from '../../../domain/entities/vibe-tag';
import { VTDate } from '../../../domain/value-objects/vt-date.vo';
import { UserId } from '../../../domain/value-objects/ids/user-id.vo';
import { Prisma, PrismaClient } from '../../../../prisma/generated';

export class PrismaAnalysisRepository implements IAnalysisRepository {
  constructor(private readonly prisma: PrismaClient) {}

  public async findBySong(
    title: string,
    artist: string,
    userId?: string,
    songId?: string,
  ): Promise<Analysis | null> {
    const userFilter = userId ? { userId: userId } : undefined;

    const song = await this.prisma.song.findFirst({
      where: songId
        ? { id: songId }
        : {
            title: { equals: title, mode: Prisma.QueryMode.insensitive },
            artist: { equals: artist, mode: Prisma.QueryMode.insensitive },
          },
      include: {
        songTags: {
          where: {
            OR: [{ tag: { type: 'SYSTEM' } }, ...(userFilter ? [userFilter] : [])],
          },
          include: {
            tag: true,
          },
        },
      },
    });

    if (!song) {
      return null;
    }

    const tags = song.songTags.map((st) => {
      let source: VibeTagSource = 'user';
      if (st.tag.type === 'SYSTEM') {
        source = 'ai';
      }
      return VibeTag.create(st.tag.name, source, st.tag.id, st.tag.description || undefined);
    });

    const metadata = SongMetadata.create({
      title: song.title,
      artist: song.artist,
      appleMusicId: song.appleMusicId || undefined,
      album: song.album || undefined,
      genre: song.genre || undefined,
    });

    return Analysis.create(metadata, tags, VTDate.now(), song.id);
  }

  public async save(analysis: Analysis): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      // 1. Upsert Song
      await tx.song.upsert({
        where: { id: analysis.songId.value },
        update: {
          title: analysis.songMetadata.title,
          artist: analysis.songMetadata.artist,
          appleMusicId: analysis.songMetadata.appleMusicId,
          album: analysis.songMetadata.album,
          genre: analysis.songMetadata.genre,
          artworkUrl: analysis.songMetadata.artworkUrl,
        },
        create: {
          id: analysis.songId.value,
          title: analysis.songMetadata.title,
          artist: analysis.songMetadata.artist,
          appleMusicId: analysis.songMetadata.appleMusicId,
          album: analysis.songMetadata.album,
          genre: analysis.songMetadata.genre,
          artworkUrl: analysis.songMetadata.artworkUrl ?? null,
        },
      });

      // 2. Ensure System User exists
      const systemUser = await tx.user.upsert({
        where: { appleUserIdentifier: 'SYSTEM' },
        update: {},
        create: {
          appleUserIdentifier: 'SYSTEM',
        },
      });
      const systemUserId = systemUser.id;

      // Deduplicate tags by name to avoid unique constraint violations
      const uniqueTags = Array.from(new Map(analysis.tags.map((tag) => [tag.name, tag])).values());

      // 3. Process Tags (FIX: Lookup by Name, not ID)
      for (const tagDomain of uniqueTags) {
        if (tagDomain.source === 'user') {
          throw new Error(
            'Cannot save USER tags in Analysis save() without explicit user context.',
          );
        }

        const targetType = 'SYSTEM'; // Since we rejected USER, it must be AI -> SYSTEM

        let dbTag = await tx.tag.findFirst({
          where: {
            name: tagDomain.name,
            ownerId: systemUserId,
            type: targetType,
          },
        });

        if (!dbTag) {
          dbTag = await tx.tag.create({
            data: {
              name: tagDomain.name,
              description: tagDomain.description,
              color: '#808080',
              type: targetType,
              ownerId: systemUserId,
            },
          });
        }

        await tx.songTag.upsert({
          where: {
            songId_tagId_userId: {
              songId: analysis.songId.value,
              tagId: dbTag.id,
              userId: systemUserId,
            },
          },
          update: {},
          create: {
            songId: analysis.songId.value,
            tagId: dbTag.id,
            userId: systemUserId,
          },
        });
      }
    });
  }

  public async updateSongTags(
    userId: UserId,
    songId: string,
    tags: string[],
    metadata: {
      title: string;
      artist: string;
      appleMusicId?: string;
      album?: string;
      genre?: string;
      artworkUrl?: string;
    },
  ): Promise<void> {
    const uniqueTags = Array.from(new Set(tags));
    await this.prisma.$transaction(async (tx) => {
      // Upsert Song
      await tx.song.upsert({
        where: { id: songId },
        update: {
          title: metadata.title,
          artist: metadata.artist,
          appleMusicId: metadata.appleMusicId,
          album: metadata.album,
          genre: metadata.genre,
          artworkUrl: metadata.artworkUrl,
        },
        create: {
          id: songId,
          title: metadata.title,
          artist: metadata.artist,
          appleMusicId: metadata.appleMusicId,
          album: metadata.album,
          genre: metadata.genre,
          artworkUrl: metadata.artworkUrl ?? null,
        },
      });

      // Delete old relations
      await tx.songTag.deleteMany({
        where: { userId: userId.value, songId: songId },
      });

      // Create new ones
      for (const tagName of uniqueTags) {
        // Find reusable tag (SYSTEM or MINE)
        // Priority Search: User custom tag OR System tag
        let tag = await tx.tag.findFirst({
          where: {
            name: tagName,
            OR: [{ ownerId: userId.value }, { type: 'SYSTEM' }],
          },
          orderBy: {
            type: 'desc', // USER comes before SYSTEM alphabetically in TagType enum
          },
        });

        if (!tag) {
          tag = await tx.tag.create({
            data: { name: tagName, color: '#808080', type: 'USER', ownerId: userId.value },
          });
        }

        await tx.songTag.create({
          data: { songId, tagId: tag.id, userId: userId.value },
        });
      }
    });
  }
}

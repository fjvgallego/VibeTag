import { IAnalysisRepository } from '../../../application/ports/analysis.repository';
import { Analysis } from '../../../domain/entities/analysis';
import { SongMetadata } from '../../../domain/value-objects/song-metadata.vo';
import { VibeTag, VibeTagSource } from '../../../domain/entities/vibe-tag';
import { prisma } from '../../database/prisma.client';
import { VTDate } from '../../../domain/value-objects/vt-date.vo';
import { UserId } from '../../../domain/value-objects/ids/user-id.vo';

export class PrismaAnalysisRepository implements IAnalysisRepository {
  public async findBySong(
    title: string,
    artist: string,
    userId?: string,
    songId?: string,
  ): Promise<Analysis | null> {
    const userFilter = userId ? { userId: userId } : undefined;

    const song = await prisma.song.findFirst({
      where: songId
        ? { id: songId }
        : {
            title: { equals: title, mode: 'insensitive' },
            artist: { equals: artist, mode: 'insensitive' },
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
      return VibeTag.create(st.tag.name, source, st.tag.id);
    });

    const metadata = SongMetadata.create(song.title, song.artist, undefined, undefined);

    return Analysis.create(metadata, tags, VTDate.now(), song.id);
  }

  public async save(analysis: Analysis): Promise<void> {
    await prisma.$transaction(async (tx) => {
      // 1. Upsert Song
      await tx.song.upsert({
        where: { id: analysis.songId.value },
        update: {
          title: analysis.songMetadata.title,
          artist: analysis.songMetadata.artist,
        },
        create: {
          id: analysis.songId.value,
          title: analysis.songMetadata.title,
          artist: analysis.songMetadata.artist,
          artworkUrl: '',
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

      // 3. Process Tags (FIX: Lookup by Name, not ID)
      for (const tagDomain of analysis.tags) {
        const targetType = tagDomain.source === 'ai' ? 'SYSTEM' : 'USER';

        let dbTag = await tx.tag.findFirst({
          where: {
            name: tagDomain.name,
            type: targetType,
          },
        });

        if (!dbTag) {
          dbTag = await tx.tag.create({
            data: {
              name: tagDomain.name,
              color: '#808080',
              type: targetType,
              ownerId: targetType === 'USER' ? '...' : systemUserId,
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
    metadata: { title: string; artist: string },
  ): Promise<void> {
    const uniqueTags = Array.from(new Set(tags));
    await prisma.$transaction(async (tx) => {
      // Upsert Song
      await tx.song.upsert({
        where: { id: songId },
        update: { title: metadata.title, artist: metadata.artist },
        create: { id: songId, title: metadata.title, artist: metadata.artist, artworkUrl: '' },
      });

      // Delete old relations
      await tx.songTag.deleteMany({
        where: { userId: userId.value, songId: songId },
      });

      // Create new ones
      for (const tagName of uniqueTags) {
        // Find reusable tag (SYSTEM or MINE)
        let tag = await tx.tag.findFirst({
          where: {
            name: tagName,
            OR: [{ type: 'SYSTEM' }, { ownerId: userId.value }],
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

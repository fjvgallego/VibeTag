import { IAnalysisRepository } from '../../../application/ports/analysis.repository';
import { Analysis } from '../../../domain/entities/analysis';
import { SongMetadata } from '../../../domain/value-objects/song-metadata.vo';
import { VibeTag, VibeTagSource } from '../../../domain/entities/vibe-tag';
import { prisma } from '../../database/prisma.client';
import { VTDate } from '../../../domain/value-objects/vt-date.vo';
import { UserId } from '../../../domain/value-objects/ids/user-id.vo';

export class PrismaAnalysisRepository implements IAnalysisRepository {
  public async findBySong(title: string, artist: string, userId?: string, songId?: string): Promise<Analysis | null> {
    const song = await prisma.song.findFirst({
      where: songId ? { id: songId } : { title: title, artist: artist },
      include: {
        songTags: {
          where: {
            OR: [{ tag: { type: 'SYSTEM' } }, ...(userId ? [{ userId: userId }] : [])],
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

    const metadata = SongMetadata.create(
      song.title,
      song.artist,
      undefined, // album and genre mapping depends on schema
      undefined,
    );

    const tags = song.songTags.map((st) => {
      let source: VibeTagSource = 'user';
      if (st.tag.type === 'SYSTEM') {
        source = 'ai';
      }
      return VibeTag.create(st.tag.name, source, st.tag.id);
    });

    // We assume a 'createdAt' exists or we use a fallback
    return Analysis.create(metadata, tags, VTDate.now(), song.id);
  }

  public async save(analysis: Analysis): Promise<void> {
    // Persist Analysis aggregate: song, tags and pivot SongTag rows.
    // Note: This uses simple defaults for fields like `color` and `userId`.
    await prisma.$transaction(async (tx) => {
      await tx.song.upsert({
        where: { id: analysis.id.value },
        update: {
          title: analysis.songMetadata.title,
          artist: analysis.songMetadata.artist,
        },
        create: {
          id: analysis.id.value,
          title: analysis.songMetadata.title,
          artist: analysis.songMetadata.artist,
          artworkUrl: '',
        },
      });

      // Persist pivot relation. `userId` is required by schema.
      // For AI-generated tags, we assign them to a 'SYSTEM' user.
      const systemUser = await tx.user.upsert({
        where: { appleUserIdentifier: 'SYSTEM' },
        update: {},
        create: {
          appleUserIdentifier: 'SYSTEM',
        },
      });
      const placeholderUserId = systemUser.id;

      for (const tag of analysis.tags) {
        const tagType = tag.source === 'ai' ? 'SYSTEM' : 'USER';

        await tx.tag.upsert({
          where: { id: tag.id.value },
          update: {
            name: tag.name,
            type: tagType,
          },
          create: {
            id: tag.id.value,
            name: tag.name,
            color: '',
            type: tagType,
          },
        });

        await tx.songTag.upsert({
          where: {
            songId_tagId_userId: {
              songId: analysis.id.value,
              tagId: tag.id.value,
              userId: placeholderUserId,
            },
          },
          update: {},
          create: {
            songId: analysis.id.value,
            tagId: tag.id.value,
            userId: placeholderUserId,
          },
        });
      }
    });
  }

  public async updateSongTags(userId: UserId, songId: string, tags: string[]): Promise<void> {
    await prisma.$transaction(async (tx) => {
      // 1. Ensure the song exists
      await tx.song.upsert({
        where: { id: songId },
        update: {},
        create: {
          id: songId,
          title: 'Unknown Title',
          artist: 'Unknown Artist',
        },
      });

      // 2. Remove existing tags for this user and song
      await tx.songTag.deleteMany({
        where: {
          userId: userId.value,
          songId: songId,
        },
      });

      // 3. Link new tags
      for (const tagName of tags) {
        // Find if a system tag or user tag already exists with this name
        let tag = await tx.tag.findFirst({
          where: { name: tagName },
        });

        if (!tag) {
          tag = await tx.tag.create({
            data: {
              name: tagName,
              color: '#808080',
              type: 'USER',
              ownerId: userId.value,
            },
          });
        }

        await tx.songTag.create({
          data: {
            songId: songId,
            tagId: tag.id,
            userId: userId.value,
          },
        });
      }
    });
  }
}

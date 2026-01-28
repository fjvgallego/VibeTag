import { IAnalysisRepository } from '../../application/ports/analysis.repository';
import { Analysis } from '../../domain/entities/analysis';
import { SongMetadata } from '../../domain/value-objects/song-metadata';
import { VibeTag, VibeTagSource } from '../../domain/entities/vibe-tag';
import { prisma } from '../database/prisma.client';

export class PrismaAnalysisRepository implements IAnalysisRepository {
  public async findBySong(title: string, artist: string): Promise<Analysis | null> {
    // Note: The current schema.prisma might not match this exactly yet.
    // This implementation assumes a structure that can store Analysis and Tags.
    // For now, we use a findFirst on Song if it exists and map it.

    const song = await prisma.song.findFirst({
      where: {
        title: title,
        artist: artist,
      },
      include: {
        songTags: {
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
    return Analysis.create(metadata, tags, new Date(), song.id);
  }

  public async save(analysis: Analysis): Promise<void> {
    // Persist Analysis aggregate: song, tags and pivot SongTag rows.
    // Note: This uses simple defaults for fields like `color` and `userId`.
    await prisma.$transaction(async (tx) => {
      await tx.song.upsert({
        where: { id: analysis.id },
        update: {
          title: analysis.songMetadata.title,
          artist: analysis.songMetadata.artist,
        },
        create: {
          id: analysis.id,
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
          where: { id: tag.id },
          update: {
            name: tag.name,
            type: tagType,
          },
          create: {
            id: tag.id,
            name: tag.name,
            color: '',
            type: tagType,
          },
        });

        await tx.songTag.upsert({
          where: {
            songId_tagId_userId: { songId: analysis.id, tagId: tag.id, userId: placeholderUserId },
          },
          update: {},
          create: {
            songId: analysis.id,
            tagId: tag.id,
            userId: placeholderUserId,
          },
        });
      }
    });
  }
}

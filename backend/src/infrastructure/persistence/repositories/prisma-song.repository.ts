import { ISongRepository, UserSongData } from '../../../application/ports/song.repository';
import { prisma } from '../../database/prisma.client';
import { Song } from '../../../domain/entities/song';
import { SongMapper } from '../../mappers/song.mapper';
import { Prisma } from '../../../../prisma/generated';

export class PrismaSongRepository implements ISongRepository {
  public async findUserLibrary(
    userId: string,
    options?: { page: number; limit: number },
  ): Promise<UserSongData[]> {
    const { page = 1, limit = 50 } = options || {};
    const skip = (page - 1) * limit;

    const songs = await prisma.song.findMany({
      where: {
        songTags: { some: { userId: userId } },
      },
      take: limit,
      skip: skip,
      orderBy: { id: 'asc' },
      select: {
        id: true,
        songTags: {
          where: { userId: userId },
          select: {
            tag: {
              select: { name: true },
            },
          },
        },
      },
    });

    return songs.map((song) => ({
      id: song.id,
      tags: song.songTags.map((st) => st.tag.name),
    }));
  }

  public async findSongsByTags(
    tags: string[],
    userId: string,
    limit: number = 50,
  ): Promise<Song[]> {
    const songs = await prisma.song.findMany({
      where: {
        songTags: {
          some: {
            userId: userId,
            tag: {
              OR: [
                { name: { in: tags, mode: Prisma.QueryMode.insensitive } },
                ...tags.map((tag) => ({
                  description: { contains: tag, mode: Prisma.QueryMode.insensitive },
                })),
              ],
            },
          },
        },
      },
      take: limit * 2, // Fetch extra for in-memory ranking
      include: {
        songTags: {
          where: { userId: userId },
          include: {
            tag: true,
          },
        },
      },
    });

    return songs.map((s) => SongMapper.toDomain(s));
  }
}

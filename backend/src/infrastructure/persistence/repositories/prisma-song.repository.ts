import { ISongRepository, UserSongData } from '../../../application/ports/song.repository';
import { Song } from '../../../domain/entities/song';
import { SongMapper } from '../../mappers/song.mapper';
import { Prisma, PrismaClient } from '../../../../prisma/generated';

export class PrismaSongRepository implements ISongRepository {
  constructor(private readonly prisma: PrismaClient) {}

  public async findUserLibrary(
    userId: string,
    options?: { page: number; limit: number },
  ): Promise<UserSongData[]> {
    const { page = 1, limit = 50 } = options || {};
    const skip = (page - 1) * limit;

    const songs = await this.prisma.song.findMany({
      where: {
        songTags: { some: { userId: userId } },
      },
      take: limit,
      skip: skip,
      orderBy: { id: 'asc' },
      select: {
        id: true,
        appleMusicId: true,
        artworkUrl: true,
        songTags: {
          where: { userId: userId },
          select: {
            tag: {
              select: { name: true, type: true, color: true },
            },
          },
        },
      },
    });

    return songs.map((song) => ({
      id: song.id,
      appleMusicId: song.appleMusicId || undefined,
      artworkUrl: song.artworkUrl || undefined,
      tags: song.songTags.map((st) => ({
        name: st.tag.name,
        type: st.tag.type as 'SYSTEM' | 'USER',
        color: st.tag.color,
      })),
    }));
  }

  public async findSongsByTags(
    tags: string[],
    userId: string,
    limit: number = 50,
  ): Promise<Song[]> {
    const songs = await this.prisma.song.findMany({
      where: {
        // MUST have a tag belonging to THIS user that matches the search
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
      take: limit,
      include: {
        songTags: {
          where: {
            userId: userId,
          },
          include: {
            tag: true,
          },
        },
      },
    });

    return songs.map((s) => SongMapper.toDomain(s));
  }
}

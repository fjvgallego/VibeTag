import { ISongRepository, UserSongData } from '../../../application/ports/song.repository';
import { prisma } from '../../database/prisma.client';

export class PrismaSongRepository implements ISongRepository {
  public async findUserLibrary(userId: string): Promise<UserSongData[]> {
    const songs = await prisma.song.findMany({
      where: {
        songTags: { some: { userId: userId } },
      },
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
}

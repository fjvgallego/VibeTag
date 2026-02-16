import { PrismaClient, Prisma } from '../../../../prisma/generated';
import { UserRepository } from '../../../application/ports/user.repository';
import { User } from '../../../domain/entities/user';
import { AppleId } from '../../../domain/value-objects/ids/apple-id.vo';
import { UserId } from '../../../domain/value-objects/ids/user-id.vo';
import { UserMapper } from '../../mappers/user.mapper';

export class PrismaUserRepository implements UserRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findByAppleId(appleId: AppleId): Promise<User | null> {
    const user = await this.prisma.user.findUnique({
      where: {
        appleUserIdentifier: appleId.value,
      },
    });

    if (!user) {
      return null;
    }

    return UserMapper.toDomain(user);
  }

  async findById(id: UserId): Promise<User | null> {
    const user = await this.prisma.user.findUnique({
      where: {
        id: id.value,
      },
    });

    if (!user) {
      return null;
    }

    return UserMapper.toDomain(user);
  }

  async save(user: User): Promise<void> {
    const data = UserMapper.toPersistence(user);
    await this.prisma.user.upsert({
      where: {
        id: user.id.value,
      },
      update: data,
      create: data,
    });
  }

  async upsertByAppleId(user: User): Promise<User> {
    const data = UserMapper.toPersistence(user);

    // Build update object with non-null and non-empty fields
    const updateData: Prisma.UserUpdateInput = {};
    if (data.email != null && data.email.trim() !== '') updateData.email = data.email;
    if (data.firstName != null && data.firstName.trim() !== '')
      updateData.firstName = data.firstName;
    if (data.lastName != null && data.lastName.trim() !== '') updateData.lastName = data.lastName;

    const savedUser = await this.prisma.user.upsert({
      where: {
        appleUserIdentifier: user.appleId.value,
      },
      update: updateData,
      create: data,
    });
    return UserMapper.toDomain(savedUser);
  }

  async delete(id: UserId): Promise<void> {
    // Use transaction to ensure proper cascade deletion order
    // 1. Delete all SongTags for this user
    // 2. Delete all Tags owned by this user
    // 3. Delete the user
    // This respects the RESTRICT constraint on SongTag.tagId
    await this.prisma.$transaction(async (tx) => {
      const userId = id.value;

      // First, delete all SongTags where this user is referenced
      await tx.songTag.deleteMany({
        where: { userId },
      });

      // Then, delete all Tags owned by this user
      await tx.tag.deleteMany({
        where: { ownerId: userId },
      });

      // Finally, delete the user
      await tx.user.delete({
        where: { id: userId },
      });
    });
  }
}

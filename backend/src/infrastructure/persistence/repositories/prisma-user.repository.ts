import { PrismaClient } from '../../../../prisma/generated';
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
}

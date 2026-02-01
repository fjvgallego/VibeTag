import { User as PrismaUser } from '../../../prisma/generated';
import { User } from '../../domain/entities/user';
import { UserId } from '../../domain/value-objects/ids/user-id.vo';
import { Email } from '../../domain/value-objects/email.vo';
import { AppleId } from '../../domain/value-objects/ids/apple-id.vo';
import { VTDate } from '../../domain/value-objects/vt-date.vo';

export class UserMapper {
  static toDomain(prismaUser: PrismaUser): User {
    return new User(
      UserId.create(prismaUser.id),
      prismaUser.email ? Email.create(prismaUser.email) : null,
      prismaUser.firstName,
      prismaUser.lastName,
      AppleId.create(prismaUser.appleUserIdentifier),
      VTDate.create(prismaUser.createdAt),
    );
  }

  static toPersistence(user: User): PrismaUser {
    return {
      id: user.id.value,
      email: user.email ? user.email.value : null,
      firstName: user.firstName,
      lastName: user.lastName,
      appleUserIdentifier: user.appleId.value,
      createdAt: new Date(user.createdAt.value),
    };
  }
}

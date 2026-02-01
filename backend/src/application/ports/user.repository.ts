import { User } from '../../domain/entities/user';
import { AppleId } from '../../domain/value-objects/ids/apple-id.vo';
import { UserId } from '../../domain/value-objects/ids/user-id.vo';

export interface UserRepository {
  findByAppleId(appleId: AppleId): Promise<User | null>;
  findById(id: UserId): Promise<User | null>;
  save(user: User): Promise<void>;
  delete(id: UserId): Promise<void>;
}

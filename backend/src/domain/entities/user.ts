import { AppleId } from '../value-objects/ids/apple-id.vo';
import { UserId } from '../value-objects/ids/user-id.vo';
import { Email } from '../value-objects/email.vo';
import { VTDate } from '../value-objects/vt-date.vo';
import { randomUUID } from 'crypto';

export class User {
  constructor(
    public readonly id: UserId,
    public readonly email: Email | null,
    public readonly firstName: string | null,
    public readonly lastName: string | null,
    public readonly appleId: AppleId,
    public readonly createdAt: VTDate,
  ) {}

  public static create(
    email: Email | null,
    firstName: string | null,
    lastName: string | null,
    appleId: AppleId,
  ): User {
    return new User(UserId.create(randomUUID()), email, firstName, lastName, appleId, VTDate.now());
  }
}

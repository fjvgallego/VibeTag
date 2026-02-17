import { describe, it, expect } from 'vitest';
import { User } from '../../../domain/entities/user';
import { Email } from '../../../domain/value-objects/email.vo';
import { AppleId } from '../../../domain/value-objects/ids/apple-id.vo';
import { UserId } from '../../../domain/value-objects/ids/user-id.vo';

describe('User Entity', () => {
  const email = Email.create('john@example.com');
  const appleId = AppleId.create('apple-123');

  it('should create a valid User with all fields', () => {
    const user = User.create(email, 'John', 'Doe', appleId);

    expect(user).toBeInstanceOf(User);
    expect(user.id).toBeInstanceOf(UserId);
    expect(user.email?.value).toBe('john@example.com');
    expect(user.firstName).toBe('John');
    expect(user.lastName).toBe('Doe');
    expect(user.appleId.value).toBe('apple-123');
    expect(user.createdAt).toBeDefined();
  });

  it('should generate a unique UUID for each user', () => {
    const user1 = User.create(email, 'John', 'Doe', appleId);
    const user2 = User.create(email, 'John', 'Doe', appleId);

    expect(user1.id.value).not.toBe(user2.id.value);
  });

  it('should create a User with null email', () => {
    const user = User.create(null, 'John', 'Doe', appleId);

    expect(user.email).toBeNull();
    expect(user.firstName).toBe('John');
  });

  it('should create a User with null firstName and lastName', () => {
    const user = User.create(email, null, null, appleId);

    expect(user.firstName).toBeNull();
    expect(user.lastName).toBeNull();
    expect(user.email?.value).toBe('john@example.com');
  });

  it('should have a valid UUID as id', () => {
    const user = User.create(email, 'John', 'Doe', appleId);

    expect(user.id.value).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
    );
  });
});

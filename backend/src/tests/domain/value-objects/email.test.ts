import { describe, it, expect } from 'vitest';
import { Email } from '../../../domain/value-objects/email.vo';
import { ValidationError } from '../../../domain/errors/app-error';

describe('Email Value Object', () => {
  it('should create a valid Email', () => {
    const email = Email.create('john@example.com');

    expect(email.value).toBe('john@example.com');
  });

  it('should normalize email to lowercase', () => {
    const email = Email.create('John@Example.COM');

    expect(email.value).toBe('john@example.com');
  });

  it('should trim whitespace', () => {
    const email = Email.create('  john@example.com  ');

    expect(email.value).toBe('john@example.com');
  });

  it('should throw ValidationError for empty string', () => {
    expect(() => Email.create('')).toThrow(ValidationError);
    expect(() => Email.create('')).toThrow('Email is required');
  });

  it('should throw ValidationError for invalid format (no @)', () => {
    expect(() => Email.create('not-an-email')).toThrow(ValidationError);
    expect(() => Email.create('not-an-email')).toThrow('Invalid email format');
  });

  it('should throw ValidationError for invalid format (no domain)', () => {
    expect(() => Email.create('user@')).toThrow(ValidationError);
  });

  it('should throw ValidationError for invalid format (no TLD)', () => {
    expect(() => Email.create('user@domain')).toThrow(ValidationError);
  });

  describe('equals', () => {
    it('should return true for same email addresses', () => {
      const email1 = Email.create('john@example.com');
      const email2 = Email.create('john@example.com');

      expect(email1.equals(email2)).toBe(true);
    });

    it('should return false for different email addresses', () => {
      const email1 = Email.create('john@example.com');
      const email2 = Email.create('jane@example.com');

      expect(email1.equals(email2)).toBe(false);
    });

    it('should return true for case-different but same email', () => {
      const email1 = Email.create('John@Example.com');
      const email2 = Email.create('john@example.com');

      expect(email1.equals(email2)).toBe(true);
    });
  });
});

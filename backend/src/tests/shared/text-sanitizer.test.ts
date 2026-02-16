import { describe, it, expect } from 'vitest';
import { TextSanitizer } from '../../shared/text-sanitizer';

describe('TextSanitizer', () => {
  const sanitizer = new TextSanitizer();

  it('should return empty string for null or undefined or empty input', () => {
    expect(sanitizer.sanitize('')).toBe('');
    expect(sanitizer.sanitize(null as unknown as string)).toBe('');
    expect(sanitizer.sanitize(undefined as unknown as string)).toBe('');
  });

  it('should trim whitespace', () => {
    expect(sanitizer.sanitize('  hello  ')).toBe('hello');
  });

  it('should escape double quotes', () => {
    expect(sanitizer.sanitize('He said "Hello"')).toBe('He said \\"Hello\\"');
  });

  it('should normalize newlines to spaces', () => {
    expect(sanitizer.sanitize('Line 1\nLine 2')).toBe('Line 1 Line 2');
  });

  it('should escape backslashes before double quotes', () => {
    expect(sanitizer.sanitize('test\\"more')).toBe('test\\\\\\"more');
  });

  it('should handle complex input', () => {
    const input = '  Title: "My Song"\nArtist: "Me"  ';
    const expected = 'Title: \\"My Song\\" Artist: \\"Me\\"';
    expect(sanitizer.sanitize(input)).toBe(expected);
  });
});

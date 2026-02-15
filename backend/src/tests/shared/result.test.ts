import { describe, it, expect } from 'vitest';
import { Result } from '../../shared/result';

describe('Result', () => {
  describe('ok', () => {
    it('should create a successful result with data', () => {
      const result = Result.ok<string, Error>('hello');

      expect(result.success).toBe(true);
      expect(result.isFailure).toBe(false);
      expect(result.getValue()).toBe('hello');
    });

    it('should allow getting value from successful result', () => {
      const data = { id: 1, name: 'test' };
      const result = Result.ok<typeof data, Error>(data);

      expect(result.getValue()).toEqual(data);
    });
  });

  describe('fail', () => {
    it('should create a failed result with error', () => {
      const error = new Error('something went wrong');
      const result = Result.fail<string, Error>(error);

      expect(result.success).toBe(false);
      expect(result.isFailure).toBe(true);
      expect(result.getError()).toBe(error);
    });

    it('should store the error', () => {
      const result = Result.fail<string, string>('bad request');

      expect(result.error).toBe('bad request');
    });
  });

  describe('getValue', () => {
    it('should throw when getting value from failed result', () => {
      const result = Result.fail<string, Error>(new Error('fail'));

      expect(() => result.getValue()).toThrow('Cannot get value of a failed result.');
    });
  });

  describe('getError', () => {
    it('should throw when getting error from successful result', () => {
      const result = Result.ok<string, Error>('success');

      expect(() => result.getError()).toThrow('Cannot get error of a successful result.');
    });
  });
});

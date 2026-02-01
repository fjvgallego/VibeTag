import { describe, it, expect } from 'vitest';
import { VTDate } from '../../../domain/value-objects/vt-date.vo';
import { ValidationError } from '../../../domain/errors/app-error';

describe('VTDate', () => {
  describe('create', () => {
    it('should create a VTDate from a Date object', () => {
      const date = new Date('2023-10-27T10:00:00Z');
      const vtDate = VTDate.create(date);
      expect(vtDate.value).toBe(date.toISOString());
    });

    it('should create a VTDate from a valid UTC ISO string (Z)', () => {
      const isoString = '2023-10-27T10:00:00Z';
      const vtDate = VTDate.create(isoString);
      expect(vtDate.value).toBe(isoString);
    });

    it('should create a VTDate from a valid ISO string with positive offset', () => {
      const isoString = '2023-10-27T10:00:00+05:30';
      const vtDate = VTDate.create(isoString);
      expect(vtDate.value).toBe(isoString);
    });

    it('should create a VTDate from a valid ISO string with negative offset', () => {
      const isoString = '2023-10-27T10:00:00-08:00';
      const vtDate = VTDate.create(isoString);
      expect(vtDate.value).toBe(isoString);
    });

    it('should create a VTDate from a valid ISO string with milliseconds and Z', () => {
      const isoString = '2023-10-27T10:00:00.123Z';
      const vtDate = VTDate.create(isoString);
      expect(vtDate.value).toBe(isoString);
    });

    it('should create a VTDate from a valid ISO string with milliseconds and offset', () => {
      const isoString = '2023-10-27T10:00:00.123+02:00';
      const vtDate = VTDate.create(isoString);
      expect(vtDate.value).toBe(isoString);
    });

    it('should throw ValidationError for invalid date string', () => {
      expect(() => VTDate.create('not-a-date')).toThrow(ValidationError);
    });

    it('should throw ValidationError for incomplete ISO string', () => {
      expect(() => VTDate.create('2023-10-27')).toThrow(ValidationError);
    });

    it('should throw ValidationError for ISO string without timezone indicator', () => {
      expect(() => VTDate.create('2023-10-27T10:00:00')).toThrow(ValidationError);
    });

    it('should throw ValidationError for offset without colon (per current regex)', () => {
      // The current regex [+-]\d{2}:\d{2} requires the colon
      expect(() => VTDate.create('2023-10-27T10:00:00+0530')).toThrow(ValidationError);
    });

    it('should throw ValidationError if date is null', () => {
      expect(() => VTDate.create(null as unknown as string)).toThrow(ValidationError);
    });
  });

  describe('now', () => {
    it('should create a VTDate representing the current time', () => {
      const vtDate = VTDate.now();
      expect(vtDate.value).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
    });
  });

  describe('equals', () => {
    it('should return true for identical dates', () => {
      const date1 = VTDate.create('2023-10-27T10:00:00Z');
      const date2 = VTDate.create('2023-10-27T10:00:00Z');
      expect(date1.equals(date2)).toBe(true);
    });

    it('should return false for different dates', () => {
      const date1 = VTDate.create('2023-10-27T10:00:00Z');
      const date2 = VTDate.create('2023-10-27T11:00:00Z');
      expect(date1.equals(date2)).toBe(false);
    });

    it('should return false for different timezone representations even if same instant', () => {
      // Since it compares literal string value
      const date1 = VTDate.create('2023-10-27T10:00:00Z');
      const date2 = VTDate.create('2023-10-27T11:00:00+01:00');
      // They represent the same time, but the value object stores the string
      expect(date1.equals(date2)).toBe(false);
    });
  });
});

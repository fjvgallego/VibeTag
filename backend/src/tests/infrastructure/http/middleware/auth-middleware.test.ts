import { describe, it, expect, vi } from 'vitest';
import { createVerifyToken } from '../../../../infrastructure/http/middleware/auth-middleware';
import { ITokenService, TokenPayload } from '../../../../application/ports/token-service';
import type { Request, Response } from 'express';

function createMockRequest(authHeader?: string): Request {
  return {
    headers: authHeader ? { authorization: authHeader } : {},
    user: undefined,
  } as unknown as Request;
}

function createMockResponse(): Response & { statusCode: number; body: unknown } {
  const res = {
    statusCode: 0,
    body: null as unknown,
    status(code: number) {
      res.statusCode = code;
      return res;
    },
    json(data: unknown) {
      res.body = data;
      return res;
    },
  };
  return res as unknown as Response & { statusCode: number; body: unknown };
}

function createMockTokenService(verifyResult: TokenPayload | null = null): ITokenService {
  return {
    generate: vi.fn(),
    verify: vi.fn().mockReturnValue(verifyResult),
  };
}

describe('AuthMiddleware', () => {
  describe('createVerifyToken', () => {
    it('should call next() and set req.user for valid token', () => {
      const payload: TokenPayload = { userId: 'user-123', email: 'a@b.com' };
      const tokenService = createMockTokenService(payload);
      const verifyToken = createVerifyToken(tokenService);

      const req = createMockRequest('Bearer valid-token');
      const res = createMockResponse();
      const next = vi.fn();

      verifyToken(req, res as unknown as Response, next);

      expect(tokenService.verify).toHaveBeenCalledWith('valid-token');
      expect(next).toHaveBeenCalled();
      expect(req.user).toBeDefined();
      expect(req.user!.userId).toBe('user-123');
    });

    it('should return 401 when no token provided', () => {
      const tokenService = createMockTokenService();
      const verifyToken = createVerifyToken(tokenService);

      const req = createMockRequest();
      const res = createMockResponse();
      const next = vi.fn();

      verifyToken(req, res as unknown as Response, next);

      expect(next).not.toHaveBeenCalled();
      expect(res.statusCode).toBe(401);
      expect(res.body).toEqual({ error: 'Unauthorized: No token provided' });
    });

    it('should return 401 for invalid token', () => {
      const tokenService = createMockTokenService(null);
      const verifyToken = createVerifyToken(tokenService);

      const req = createMockRequest('Bearer invalid-token');
      const res = createMockResponse();
      const next = vi.fn();

      verifyToken(req, res as unknown as Response, next);

      expect(tokenService.verify).toHaveBeenCalledWith('invalid-token');
      expect(next).not.toHaveBeenCalled();
      expect(res.statusCode).toBe(401);
      expect(res.body).toEqual({ error: 'Unauthorized: Invalid token' });
    });

    it('should return 401 for expired token (verify returns null)', () => {
      const tokenService = createMockTokenService(null);
      const verifyToken = createVerifyToken(tokenService);

      const req = createMockRequest('Bearer expired-token');
      const res = createMockResponse();
      const next = vi.fn();

      verifyToken(req, res as unknown as Response, next);

      expect(next).not.toHaveBeenCalled();
      expect(res.statusCode).toBe(401);
    });
  });
});

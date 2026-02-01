import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { verifyToken } from '../middleware/AuthMiddleware';

export function createAuthRouter(controller: AuthController): Router {
  const router = Router();
  router.post('/apple', controller.loginWithApple.bind(controller));
  router.delete('/me', verifyToken, controller.deleteAccount.bind(controller));
  return router;
}

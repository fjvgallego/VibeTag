import { Router, RequestHandler } from 'express';
import { AuthController } from '../controllers/auth.controller';

export function createAuthRouter(controller: AuthController, verifyToken: RequestHandler): Router {
  const router = Router();
  router.post('/apple', controller.loginWithApple.bind(controller));
  router.delete('/me', verifyToken, controller.deleteAccount.bind(controller));
  return router;
}

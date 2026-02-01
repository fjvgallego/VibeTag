import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';

export function createAuthRouter(controller: AuthController): Router {
  const router = Router();
  router.post('/apple', controller.loginWithApple.bind(controller));
  return router;
}

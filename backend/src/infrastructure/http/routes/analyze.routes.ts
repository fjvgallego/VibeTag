import { Router } from 'express';
import { AnalyzeController } from '../controllers/analyze.controller';
import { softVerifyToken } from '../middleware/AuthMiddleware';

export function createAnalyzeRouter(controller: AnalyzeController): Router {
  const router = Router();
  router.post('/song', softVerifyToken, controller.analyze.bind(controller));
  return router;
}

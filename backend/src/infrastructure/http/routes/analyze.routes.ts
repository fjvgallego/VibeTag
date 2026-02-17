import { Router, RequestHandler } from 'express';
import { AnalyzeController } from '../controllers/analyze.controller';

export function createAnalyzeRouter(
  controller: AnalyzeController,
  verifyToken: RequestHandler,
): Router {
  const router = Router();
  router.post('/song', verifyToken, controller.analyze.bind(controller));
  router.post('/batch', verifyToken, controller.analyzeBatch.bind(controller));
  return router;
}

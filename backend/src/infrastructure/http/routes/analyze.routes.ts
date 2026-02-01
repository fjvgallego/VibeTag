import { Router } from 'express';
import { AnalyzeController } from '../controllers/analyze.controller';

export function createAnalyzeRouter(controller: AnalyzeController): Router {
  const router = Router();
  router.post('/song', controller.analyze.bind(controller));
  return router;
}

import { ServerDependencies } from '../../application/ports/server-dependencies';
import { PrismaAnalysisRepository } from '../../infrastructure/adapters/prisma-analysis.repository';
import { AnalyzeUseCase } from '../../application/use-cases/analyze.use-case';
import { IAIService } from '../../domain/services/ai-service.interface';
import { GeminiAIService } from '../../infrastructure/adapters/gemini-ai.service';
import { TextSanitizer } from '../../shared/text-sanitizer';
import { config } from '../config/config';

export interface Dependencies extends ServerDependencies {
  // Add other dependencies here if needed (e.g. services, repositories that are not use-cases but needed for something else, though usually only use-cases are exposed to the entry point)
  aiService: IAIService;
  analysisRepo: PrismaAnalysisRepository;
}

export function buildContainer(): Dependencies {
  const analysisRepo = new PrismaAnalysisRepository();
  const sanitizer = new TextSanitizer();
  const aiService = new GeminiAIService(config.GEMINI_API_KEY, sanitizer);

  const analyzeUseCase = new AnalyzeUseCase(analysisRepo, aiService);

  return {
    analyzeUseCase,
    aiService,
    analysisRepo,
  };
}

import { ServerDependencies } from '../../application/ports/server-dependencies';
import { PrismaAnalysisRepository } from '../../infrastructure/adapters/prisma-analysis.repository';
import { AnalyzeUseCase } from '../../application/use-cases/analyze.use-case';
import { IAIService } from '../../domain/services/ai-service.interface';
import { SongMetadata } from '../../domain/value-objects/song-metadata';

// Temporary implementation until real AI service is available
class SimpleAIService implements IAIService {
  public async getVibesForSong(_: SongMetadata): Promise<string[]> {
    return ['chill', 'uplifting'];
  }
}

export interface Dependencies extends ServerDependencies {
  // Add other dependencies here if needed (e.g. services, repositories that are not use-cases but needed for something else, though usually only use-cases are exposed to the entry point)
  aiService: IAIService;
  analysisRepo: PrismaAnalysisRepository;
}

export function buildContainer(): Dependencies {
  const analysisRepo = new PrismaAnalysisRepository();
  const aiService = new SimpleAIService();

  const analyzeUseCase = new AnalyzeUseCase(analysisRepo, aiService);

  return {
    analyzeUseCase,
    aiService,
    analysisRepo,
  };
}

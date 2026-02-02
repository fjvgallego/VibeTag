import { ServerDependencies } from '../../application/ports/server-dependencies';
import { PrismaAnalysisRepository } from '../../infrastructure/persistence/repositories/prisma-analysis.repository';
import { AnalyzeUseCase } from '../../application/use-cases/analyze.use-case';
import { UpdateSongTagsUseCase } from '../../application/use-cases/update-song-tags.use-case';
import { GetUserLibraryUseCase } from '../../application/use-cases/get-user-library.use-case';
import { IAIService } from '../../domain/services/ai-service.interface';
import { GeminiAIService } from '../../infrastructure/services/gemini-ai.service';
import { TextSanitizer } from '../../shared/text-sanitizer';
import { config } from '../config/config';
import { PrismaUserRepository } from '../../infrastructure/persistence/repositories/prisma-user.repository';
import { PrismaSongRepository } from '../../infrastructure/persistence/repositories/prisma-song.repository';
import { AppleAuthProvider } from '../../infrastructure/services/apple-auth.provider';
import { JwtTokenService } from '../../infrastructure/security/jwt-token.service';
import { LoginWithAppleUseCase } from '../../application/use-cases/auth/login-with-apple.use-case';
import { DeleteAccountUseCase } from '../../application/use-cases/auth/delete-account.use-case';
import { prisma } from '../../infrastructure/database/prisma.client';
import { ITokenService } from '../../application/ports/token-service';

export interface Dependencies extends ServerDependencies {
  aiService: IAIService;
  analysisRepo: PrismaAnalysisRepository;
  songRepo: PrismaSongRepository;
  userRepo: PrismaUserRepository;
  authProvider: AppleAuthProvider;
  tokenService: ITokenService;
  loginWithAppleUseCase: LoginWithAppleUseCase;
  deleteAccountUseCase: DeleteAccountUseCase;
}

export function buildContainer(): Dependencies {
  const analysisRepo = new PrismaAnalysisRepository();
  const songRepo = new PrismaSongRepository();
  const sanitizer = new TextSanitizer();
  const aiService = new GeminiAIService(config.GEMINI_API_KEY, sanitizer);

  const userRepo = new PrismaUserRepository(prisma);
  const authProvider = new AppleAuthProvider();
  const tokenService = new JwtTokenService();

  const analyzeUseCase = new AnalyzeUseCase(analysisRepo, aiService);
  const updateSongTagsUseCase = new UpdateSongTagsUseCase(analysisRepo);
  const getUserLibraryUseCase = new GetUserLibraryUseCase(songRepo);
  const loginWithAppleUseCase = new LoginWithAppleUseCase(userRepo, authProvider, tokenService);
  const deleteAccountUseCase = new DeleteAccountUseCase(userRepo);

  return {
    analyzeUseCase,
    updateSongTagsUseCase,
    getUserLibraryUseCase,
    aiService,
    analysisRepo,
    songRepo,
    userRepo,
    authProvider,
    tokenService,
    loginWithAppleUseCase,
    deleteAccountUseCase,
  };
}

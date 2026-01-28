import { createGoogleGenerativeAI } from '@ai-sdk/google';
import { generateText } from 'ai';
import { IAIService } from '../../domain/services/ai-service.interface';
import { SongMetadata } from '../../domain/value-objects/song-metadata';
import { ITextSanitizer } from '../../shared/text-sanitizer';

export class GeminiAIService implements IAIService {
  private readonly google: ReturnType<typeof createGoogleGenerativeAI>;
  private readonly modelName: string;
  private readonly sanitizer: ITextSanitizer;

  constructor(apiKey: string, sanitizer: ITextSanitizer, modelName: string = 'gemini-2.5-flash') {
    this.google = createGoogleGenerativeAI({
      apiKey,
    });
    this.modelName = modelName;
    this.sanitizer = sanitizer;
  }

  public async getVibesForSong(song: SongMetadata): Promise<string[]> {
    const prompt = this.constructPrompt(song);

    try {
      const { text } = await generateText({
        model: this.google(this.modelName),
        prompt: prompt,
      });

      return this.parseResponse(text);
    } catch (error) {
      console.error('Error calling Gemini API via AI SDK:', error);
      throw new Error('Failed to get vibes from Gemini AI');
    }
  }

  private constructPrompt(song: SongMetadata): string {
    return `
        You are a music curator. Analyze this song:
        Title: "${this.sanitizer.sanitize(song.title)}"
        Artist: "${this.sanitizer.sanitize(song.artist)}"
        Album: "${this.sanitizer.sanitize(song.album || 'Unknown')}"
        Genre: "${this.sanitizer.sanitize(song.genre || 'Unknown')}"

        Task: Return strictly a valid JSON array containing exactly 3 short, descriptive mood/context tags (e.g., "Night Drive", "Gym Focus", "Melancholy").
        Example Output: ["Chill", "Summer", "Road Trip"]
        
        IMPORTANT: Return ONLY the JSON array. Do not include markdown formatting like  \`\`\`json or \`\`\`. 
      `;
  }

  private parseResponse(text: string): string[] {
    try {
      const cleanedText = text
        .replace(/```json/g, '')
        .replace(/```/g, '')
        .trim();
      const vibes = JSON.parse(cleanedText);

      if (!Array.isArray(vibes)) {
        console.warn('Gemini response was not an array:', cleanedText);
        return ['Unknown Vibe'];
      }

      return vibes.map((v) => String(v).toLowerCase()).filter((tag: string) => tag.length > 0);
    } catch (error) {
      console.warn('Failed to parse Gemini response:', text, error);
      return ['Unknown Vibe'];
    }
  }
}
